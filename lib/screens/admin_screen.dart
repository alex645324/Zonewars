import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/player_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import 'code_floor_screen.dart';
import 'admin_login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Firebase and service instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final GameStateService _gameStateService = GameStateService();

  // Text input controllers
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _timerMinutesController = TextEditingController(text: "3");

  // Game state tracking variables
  List<Player> _players = [];
  String _selectedZone = 'FLOOR 2';
  bool _isLoading = true;

  // Stream subscriptions for real-time updates
  StreamSubscription? _playersSubscription;
  StreamSubscription? _gameStateSubscription;

  // Timer related properties
  Timer? _redirectTimer;
  int _timerCountdown = 0;
  bool _timerActive = false;

  // Game state tracking
  String _gameStatus = GameStateService.LOBBY;
  String _gameId = '';
  Timestamp? _gameStartTime;
  Timestamp? _gameEndTime;

  @override
  void initState() {
    // Initialize the screen and set up listeners
    super.initState();
    _checkAuthorization();
    _loadPlayers();
    _setupGameStateListener();
  }

  @override
  void dispose() {
    // Clean up resources when screen is closed
    _announcementController.dispose();
    _zoneController.dispose();
    _timerMinutesController.dispose();
    _playersSubscription?.cancel();
    _gameStateSubscription?.cancel();
    _redirectTimer?.cancel();
    _authService.clearAdminStatus();
    super.dispose();
  }

  void _checkAuthorization() {
    if (!_authService.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminLoginScreen(),
          ),
        );
      });
    }
  }

  void _setupGameStateListener() {
    _gameStateSubscription = _gameStateService.gameStateStream().listen((gameState) {
      setState(() {
        _gameStatus = gameState['status'] as String? ?? GameStateService.LOBBY;
        _gameId = gameState['current_game_id'] as String? ?? '';
        _gameStartTime = gameState['start_time'] as Timestamp?;
        _gameEndTime = gameState['end_time'] as Timestamp?;
      });
    });
  }

  void _loadPlayers() {
    _playersSubscription = _firestore
        .collection('players')
        .snapshots()
        .listen((snapshot) {
      final List<Player> loadedPlayers = [];
      for (final doc in snapshot.docs) {
        loadedPlayers.add(
          Player.fromMap(
            doc.data(),
            id: doc.id,
            currentPlayerId: 'admin', // Admin is not a player
          ),
        );
      }

      setState(() {
        _players = loadedPlayers;
        _isLoading = false;
      });
    });
  }

  Future<void> _handleStartGame() async {
    // Starts a new game session
    try {
      // Don't allow starting if there are no players
      if (_players.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No players to start the game with!'),
            backgroundColor: Color(0xFFF36567),
          ),
        );
        return;
      }

      // Set initial deadline for all players
      final deadline = DateTime.now().add(const Duration(minutes: 3));
      final batch = _firestore.batch();

      for (final player in _players) {
        batch.update(_firestore.collection('players').doc(player.id), {
          'codeEntryDeadline': Timestamp.fromDate(deadline),
          'codeEntered': false,
        });
      }

      await batch.commit();

      // Start the game using the game state service
      await _gameStateService.startGame();
      print('Game started, about to reidrect to dashboard');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game started!'),
          backgroundColor: Colors.green,
        ),
      );

      // we are using the redirect to dashboard method 
      await _redirectUsersToDashboard();
      print('Finish calling _redirectUsersToDashboard');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting game: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }

  Future<void> _handleEndGame() async {
    // Ends the current game session
    try {
      await _gameStateService.endGame();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game ended! Players redirected to results screen.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ending game: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }

  Future<void> _handleResetGame() async {
    try {
      await _gameStateService.resetToLobby();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game reset! Players redirected to lobby.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting game: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }

  Future<void> _disqualifyPlayer(String playerId) async {
    // Removes a player from active gameplay
    try {
      await _firestore.collection('players').doc(playerId).update({
        'isActive': false,
        'isSpectator': true,
        'eliminationCount': 3,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player disqualified'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disqualifying player: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }







  // This is a redirect method that we are going to use to redirect users from the lobby to the dashbaord 
  Future<void> _redirectUsersToDashboard() async{
    print('_redirectUserToDashboard method called'); // debug log
    try {
      //Creating a field in firestore for all clients to listen to 
      await _firestore.collection('game_state').doc('redirect').set({
        'shouldRedirect': true, 
        'targetScreen': 'dashboard',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Firestore update with dashboard redirect'); // Debug log

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirected all users to Dashboard'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) { 
      print('Error in_redirectUsersToDashboard: $e');// Debug error log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error redirecting users: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }







  Future<void> _sendAnnouncement() async {
    // Sends a message to all players
    final announcement = _announcementController.text.trim();
    if (announcement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement cannot be empty'),
          backgroundColor: Color(0xFFF36567),
        ),
      );
      return;
    }

    try {
      await _firestoreService.sendAdminMessage(announcement);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement sent'),
          backgroundColor: Colors.green,
        ),
      );

      _announcementController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending announcement: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }

  void _startRedirectTimer() {
    // Starts countdown for zone change
    // Cancel any existing timer
    _redirectTimer?.cancel();

    // Parse minutes from input field
    final minutes = int.tryParse(_timerMinutesController.text) ?? 3;
    _timerCountdown = minutes * 60; // Convert to seconds

    setState(() {
      _timerActive = true;
    });

    // Start a new timer
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerCountdown > 0) {
          _timerCountdown--;
        } else {
          _timerActive = false;
          _redirectTimer?.cancel();
          _redirectAllUsers(); // Redirect all users when timer reaches zero
        }
      });
    });

    // Send announcement about the timer
    _firestoreService.sendAdminMessage(
      'ZONE CHANGE IMMINENT: Moving to $_selectedZone in $minutes minutes!'
    );
  }

  String _formatTime() {
    // Format time as mm:ss
    final minutes = (_timerCountdown / 60).floor();
    final seconds = _timerCountdown % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _cancelTimer() {
    // Cancel the active timer
    _redirectTimer?.cancel();
    setState(() {
      _timerActive = false;
    });
    _firestoreService.sendAdminMessage('Zone change canceled');
  }

  Future<void> _redirectAllUsers() async {
    // Forces all players to move to a new zone
    try {
      // Create a field in Firestore for all clients to listen to
      await _firestore.collection('game_state').doc('redirect').set({
        'shouldRedirect': true,
        'targetScreen': 'floor_code',
        'floorName': _selectedZone,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirected all users to Floor Code Screen'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error redirecting users: $e'),
          backgroundColor: const Color(0xFFF36567),
        ),
      );
    }
  }

  String _getGameStatusText() {
    // Converts game state to display text
    switch (_gameStatus) {
      case GameStateService.LOBBY:
        return 'LOBBY';
      case GameStateService.ACTIVE:
        return 'ACTIVE';
      case GameStateService.ENDED:
        return 'ENDED';
      default:
        return 'UNKNOWN';
    }
  }

  Color _getGameStatusColor() {
    // Returns appropriate color for game state
    switch (_gameStatus) {
      case GameStateService.LOBBY:
        return Colors.orange;
      case GameStateService.ACTIVE:
        return Colors.green;
      case GameStateService.ENDED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main UI construction
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADMIN PANEL',
          style: TextStyle(
            fontFamily: 'Bungee',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF50AFD5),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Game status and controls section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getGameStatusColor()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GAME CONTROLS',
                          style: TextStyle(
                            fontFamily: 'Bungee',
                            fontSize: 20,
                            color: Color(0xFF50AFD5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getGameStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'STATUS: ${_getGameStatusText()}',
                            style: const TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Game control buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _gameStatus == GameStateService.LOBBY ? _handleStartGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF50AFD5),
                              disabledBackgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'START GAME',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _gameStatus == GameStateService.ACTIVE ? _handleEndGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF36567),
                              disabledBackgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'END GAME',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _gameStatus == GameStateService.ENDED ? _handleResetGame : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'RESET GAME',
                          style: TextStyle(
                            fontFamily: 'Bungee',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // Game stats
                    if (_gameStatus == GameStateService.ACTIVE || _gameStatus == GameStateService.ENDED)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GAME STATS',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 16,
                                color: Color(0xFF50AFD5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Game ID: $_gameId',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_gameStartTime != null)
                              Text(
                                'Started: ${_gameStartTime!.toDate().toString()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            if (_gameEndTime != null)
                              Text(
                                'Ended: ${_gameEndTime!.toDate().toString()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Active: ${_players.where((p) => !p.isSpectator).length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Spectators: ${_players.where((p) => p.isSpectator).length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Players section
              const Text(
                'PLAYERS',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 20,
                  color: Color(0xFF50AFD5),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _players.isEmpty
                        ? const Center(
                            child: Text(
                              'NO ACTIVE PLAYERS',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 16,
                                color: Color(0xFF50AFD5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _players.length,
                            itemBuilder: (context, index) {
                              final player = _players[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    player.name,
                                    style: const TextStyle(
                                      fontFamily: 'Bungee',
                                      fontSize: 16,
                                      color: Color(0xFF50AFD5),
                                    ),
                                  ),
                                  subtitle: Text(
                                    player.isSpectator
                                        ? 'SPECTATOR'
                                        : 'LIVES: ${player.lives}',
                                    style: TextStyle(
                                      fontFamily: 'Bungee',
                                      fontSize: 12,
                                      color: player.isSpectator
                                          ? const Color(0xFFF36567)
                                          : Colors.black54,
                                    ),
                                  ),
                                  trailing: player.isSpectator
                                      ? const Text(
                                          'DISQUALIFIED',
                                          style: TextStyle(
                                            fontFamily: 'Bungee',
                                            fontSize: 12,
                                            color: Color(0xFFF36567),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: () =>
                                              _disqualifyPlayer(player.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFF36567),
                                          ),
                                          child: const Text(
                                            'DISQUALIFY',
                                            style: TextStyle(
                                              fontFamily: 'Bungee',
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
              ),
              const Divider(height: 32),

              // Announcements section
              const Text(
                'SEND ANNOUNCEMENT',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 20,
                  color: Color(0xFF50AFD5),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _announcementController,
                decoration: InputDecoration(
                  hintText: 'Type announcement here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF50AFD5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF50AFD5),
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50AFD5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'SEND TO ALL PLAYERS',
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),

              // Zone change section
              const Text(
                'CHANGE ZONE',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 20,
                  color: Color(0xFF50AFD5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedZone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'FLOOR 2',
                          child: Text('FLOOR 2'),
                        ),
                        DropdownMenuItem(
                          value: 'FLOOR 3',
                          child: Text('FLOOR 3'),
                        ),
                        DropdownMenuItem(
                          value: 'FLOOR 4',
                          child: Text('FLOOR 4'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedZone = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!_timerActive)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _timerMinutesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Minutes',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton(
                                  onPressed: _startRedirectTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF36567),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'START TIMER',
                                    style: TextStyle(
                                      fontFamily: 'Bungee',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _redirectAllUsers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF36567),
                              minimumSize: const Size.fromHeight(40),
                            ),
                            child: const Text(
                              'FORCE REDIRECT NOW',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'REDIRECTING IN: ${_formatTime()}',
                            style: const TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 18,
                              color: Color(0xFFF36567),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _cancelTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              minimumSize: const Size.fromHeight(40),
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'Bungee',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}