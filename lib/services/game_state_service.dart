import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage game state transitions and lifecycle
class GameStateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Game states
  static const String LOBBY = 'lobby';
  static const String ACTIVE = 'active';
  static const String ENDED = 'ended';
  
  /// Get current game state stream
  Stream<Map<String, dynamic>> gameStateStream() {
    return _db.collection('game_state').doc('current_game').snapshots().map(
      (snapshot) => snapshot.data() ?? {'status': LOBBY, 'current_game_id': ''},
    );
  }
  
  /// Initialize game state document if it doesn't exist
  Future<void> initializeGameState() async {
    final docRef = _db.collection('game_state').doc('current_game');
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      await docRef.set({
        'status': LOBBY,
        'current_game_id': '',
        'start_time': null,
        'end_time': null,
      });
    }
  }
  
  /// Start a new game
  Future<void> startGame() async {
    final String gameId = DateTime.now().millisecondsSinceEpoch.toString();
    final batch = _db.batch();
    
    // Update game state
    batch.set(_db.collection('game_state').doc('current_game'), {
      'status': ACTIVE,
      'current_game_id': gameId,
      'start_time': FieldValue.serverTimestamp(),
      'end_time': null,
    });
    
    // Reset all players
    final playersSnapshot = await _db.collection('players').get();
    for (final doc in playersSnapshot.docs) {
      batch.update(doc.reference, {
        'isActive': true,
        'isSpectator': false,
        'eliminationCount': 0,
        'codeEntered': false,
        'codeEntryDeadline': null,
      });
    }
    
    // Clear any existing redirect
    batch.set(_db.collection('game_state').doc('redirect'), {
      'shouldRedirect': false,
    });

    print('startGame setting shouldRedirect to false');
    
    // Set initial message
    batch.set(_db.collection('game_state').doc('admin_message'), {
      'message': 'Game has started! Good luck!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    print('About to commit batch in startGame');
    return batch.commit();
  }
  
  /// End the current game
  Future<void> endGame() async {
    final batch = _db.batch();
    
    // Update game state
    batch.update(_db.collection('game_state').doc('current_game'), {
      'status': ENDED,
      'end_time': FieldValue.serverTimestamp(),
    });
    
    // Set message
    batch.set(_db.collection('game_state').doc('admin_message'), {
      'message': 'Game has ended! Check the results!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Redirect all users to game end screen
    batch.set(_db.collection('game_state').doc('redirect'), {
      'shouldRedirect': true,
      'targetScreen': 'game_end',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    return batch.commit();
  }
  
  /// Reset game to lobby state
  Future<void> resetToLobby() async {
    final batch = _db.batch();
    
    // Update game state
    batch.update(_db.collection('game_state').doc('current_game'), {
      'status': LOBBY,
      'current_game_id': '',
      'start_time': null,
      'end_time': null,
    });
    
    // Redirect all users to lobby
    batch.set(_db.collection('game_state').doc('redirect'), {
      'shouldRedirect': true,
      'targetScreen': 'lobby',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Set message
    batch.set(_db.collection('game_state').doc('admin_message'), {
      'message': 'Game has been reset. Waiting for new game to start.',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    return batch.commit();
  }
  
  /// Get surviving players (winners)
  Future<List<DocumentSnapshot>> getWinners() async {
    final querySnapshot = await _db.collection('players')
        .where('isActive', isEqualTo: true)
        .where('isSpectator', isEqualTo: false)
        .get();
    
    return querySnapshot.docs;
  }

  /// Get current game state
  Future<Map<String, dynamic>> getCurrentGameState() async {
    final snapshot = await _db.collection('game_state').doc('current_game').get();
    return snapshot.data() ?? {'status': LOBBY, 'current_game_id': ''};
  }
}