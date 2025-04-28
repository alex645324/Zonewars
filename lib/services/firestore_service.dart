import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../services/auth_service.dart';


/// Service to manage Firestore interactions for Zone Wars game state and admin controls.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of all players (active and eliminated).
  Stream<List<Player>> getPlayersStream(String currentPlayerId) {
  return _db.collection('players').snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => Player.fromMap(
              doc.data(),
              id: doc.id,
              currentPlayerId: currentPlayerId,
            ))
        .toList(),
  );
}

  /// Force-eliminate a player by setting isActive to false.
  Future<void> forceEliminatePlayer(String playerId) {
    return _db.collection('players').doc(playerId).update({
      'isActive': false,
    });
  }

  /// Stream of the current admin message for real-time alerts.
  Stream<String> adminMessageStream() {
    return _db.collection('game_state').doc('admin_message').snapshots().map(
      (snapshot) => snapshot.data()?['message'] as String? ?? '',
    );
  }

  /// Send or update an admin message (e.g., "RA woke up! Move to Floor 3").
  Future<void> sendAdminMessage(String message) {
    return _db.collection('game_state').doc('admin_message').set({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of the current zone range (e.g., ["floor_3", "floor_4"]).
  Stream<List<String>> zoneRangeStream() {
    return _db.collection('game_state').doc('current_zone').snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        if (data == null) return <String>[];
        final List<dynamic> list = data['zoneRange'] as List<dynamic>? ?? [];
        return list.cast<String>();
      },
    );
  }

  /// Update the active zone range and timestamp when the zone shrinks.
  Future<void> updateZoneRange(List<String> newZoneRange) {
    return _db.collection('game_state').doc('current_zone').set({
      'zoneRange': newZoneRange,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reset the entire game: re-activate all players, clear codes and elimination counts, and reset game state.
  Future<void> resetGame(List<String> initialZoneRange) async {
    // Batch update all players
    final batch = _db.batch();
    final allPlayers = await _db.collection('players').get();
    for (final doc in allPlayers.docs) {
      batch.update(doc.reference, {
        'isActive': true,
        'lastEnteredCode': '',
        'eliminationCount': 0,
      });
    }

    // Reset zone range and clear admin message
    batch.set(
      _db.collection('game_state').doc('current_zone'),
      {
        'zoneRange': initialZoneRange,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _db.collection('game_state').doc('admin_message'),
      {'message': '', 'timestamp': FieldValue.serverTimestamp()},
    );

    return batch.commit();
  }
}