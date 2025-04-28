import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    // Initialize any debug listeners here
    print('AuthService initialized');
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  /// Holds the current player's ID
  String? currentPlayerId;

  // Add these new properties at the top with other properties
  bool _isAdmin = false;
  final String _adminPassword = const String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'admin123'
  ); // TODO: Replace with secure authentication

  // Add getter for admin status
  bool get isAdmin => _isAdmin;

  // Add this new method
  Future<bool> authenticateAdmin(String password) async {
    try {
      _isAdmin = password == _adminPassword;
      return _isAdmin;
    } catch (e) {
      print('Error authenticating admin: $e');
      return false;
    }
  }

  // Add method to clear admin status
  void clearAdminStatus() {
    _isAdmin = false;
  }

  /// Sign in the player by creating a new document in Firestore
  Future<void> signInPlayer(String nickname) async {
    try {
      if (nickname.length > 10) {
        throw Exception('Nickname too long');
      }

      String playerId = _uuid.v4();
      print('Generated playerId: $playerId');

      await _firestore.collection('players').doc(playerId).set({
        'name': nickname,
        'isActive': true,
        'lastEnteredCode': '',
        'eliminationCount': 0,
        'isSpectator': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      currentPlayerId = playerId;
      print('Set currentPlayerId: $currentPlayerId');
    } catch (e) {
      print('Error signing in player: $e');
      rethrow;
    }
  }

  /// Disqualify a player and set them to spectator mode
  Future<void> disqualifyPlayer() async {
    if (currentPlayerId == null) {
      print('Warning: Attempted to disqualify null player ID');
      return;
    }

    try {
      await _firestore.collection('players').doc(currentPlayerId).update({
        'isActive': false,
        'isSpectator': true,
        'eliminationCount': 3,
      });
      print('Player $currentPlayerId disqualified');
    } catch (e) {
      print('Error disqualifying player: $e');
      rethrow;
    }
  }

  /// Enter spectator mode without disqualification
  Future<void> enterSpectatorMode() async {
    if (currentPlayerId == null) {
      print('Warning: Attempted to enter spectator mode with null player ID');
      return;
    }

    try {
      await _firestore.collection('players').doc(currentPlayerId).update({
        'isSpectator': true,
      });
      print('Player $currentPlayerId entered spectator mode');
    } catch (e) {
      print('Error entering spectator mode: $e');
      rethrow;
    }
  }

  /// Mark the player as eliminated
  Future<void> eliminateCurrentPlayer() async {
    if (currentPlayerId == null) {
      print('Warning: Attempted to eliminate null player ID');
      return;
    }

    try {
      await _firestore.collection('players').doc(currentPlayerId).update({
        'isActive': false,
      });
      print('Player $currentPlayerId eliminated');
    } catch (e) {
      print('Error eliminating player: $e');
      rethrow;
    }
  }

  /// Update the player's last entered zone code
  Future<void> updatePlayerZoneCode(String zoneCode) async {
    if (currentPlayerId == null) {
      print('Warning: Attempted to update zone code with null player ID');
      return;
    }

    try {
      await _firestore.collection('players').doc(currentPlayerId).update({
        'lastEnteredCode': zoneCode,
      });
      print('Updated zone code for player $currentPlayerId: $zoneCode');
    } catch (e) {
      print('Error updating zone code: $e');
      rethrow;
    }
  }
}
