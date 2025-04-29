import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/game_state_service.dart';
import 'dashboard_screen.dart';
import 'game_end_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String currentPlayerName;
  
  const LobbyScreen({
    Key? key, 
    required this.currentPlayerName,
  }) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final GameStateService _gameStateService = GameStateService();
  
  List<Player> _lobbyPlayers = [];
  bool _isLoading = true;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _gameStateSubscription;
  StreamSubscription? _redirectSubscription;
  bool _showAdminMessage = false;
  String _adminMessage = '';
  StreamSubscription? _adminMessageSubscription;
  
  @override
  void initState() {
    super.initState();
    _setupGameStateListener();
    _setupPlayerListener();
    _setupAdminMessageListener();
    _setupRedirectListener();
    
    // Initialize game state if needed
    _gameStateService.initializeGameState();
  }

  void _setupGameStateListener() {
    _gameStateSubscription = _gameStateService.gameStateStream().listen((gameState) {
      final status = gameState['status'] as String? ?? GameStateService.LOBBY;
      
      // If game is active, navigate to dashboard
//      if (status == GameStateService.ACTIVE && mounted) {
//        Navigator.of(context).pushReplacement(
//          MaterialPageRoute(
//            builder: (context) => DashboardScreen(
//              currentPlayerName: widget.currentPlayerName,
//            ),
//          ),
//        );
//      }
      
      // If game has ended, navigate to end screen
      if (status == GameStateService.ENDED && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameEndScreen(
              currentPlayerName: widget.currentPlayerName,
            ),
          ),
        );
      }
    });
  }

  void _setupPlayerListener() {
    _playersSubscription = _firestore
        .collection('players')
        .snapshots()
        .listen((snapshot) {
      final List<Player> loadedPlayers = [];
      for (final doc in snapshot.docs) {
        final avatarNum = (doc.id.hashCode % 6) + 1; // 1-6 range
        final avatarPath = 'lib/assets/avatar$avatarNum.png';
        
        Player player = Player.fromMap(
          doc.data(),
          id: doc.id, 
          currentPlayerId: _authService.currentPlayerId ?? 'unknown',
        );
        
        // Manually set the avatar path after creation
        player = Player(
          id: player.id,
          name: player.name,
          avatarAsset: avatarPath,
          lives: player.lives,
          isCurrentPlayer: player.isCurrentPlayer,
          isSpectator: player.isSpectator,
        );
        
        loadedPlayers.add(player);
      }
      
      loadedPlayers.sort((a, b) {
        // Current player first, then alphabetical
        if (a.isCurrentPlayer) return -1;
        if (b.isCurrentPlayer) return 1;
        return a.name.compareTo(b.name);
      });
      
      setState(() {
        _lobbyPlayers = loadedPlayers;
        _isLoading = false;
      });
    });
  }

  void _setupAdminMessageListener() {
    _adminMessageSubscription = _firestoreService
        .adminMessageStream()
        .listen((message) {
      if (message.isNotEmpty) {
        setState(() {
          _adminMessage = message;
          _showAdminMessage = true;
        });
      }
    });
  }

  void _setupRedirectListener() {
    _redirectSubscription = _firestore
        .collection('game_state')
        .doc('redirect')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && 
          snapshot.data()?['shouldRedirect'] == true &&
          snapshot.data()?['targetScreen'] == 'dashboard') {

        // Add debug loggin here
        print('Lobby: Detected dashboard redirect: ${snapshot.data()}');
        
        // Navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                currentPlayerName: widget.currentPlayerName,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _playersSubscription?.cancel();
    _gameStateSubscription?.cancel();
    _redirectSubscription?.cancel();
    _adminMessageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'LOBBY',
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 50,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF50AFD5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'WAITING FOR ADMIN TO START THE GAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF50AFD5),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Player count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF50AFD5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'PLAYERS: ${_lobbyPlayers.length}',
                      style: const TextStyle(
                        fontFamily: 'Bungee',
                        fontSize: 16,
                        color: Color(0xFF50AFD5),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Player list
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _lobbyPlayers.isEmpty
                            ? const Center(
                                child: Text(
                                  'NO PLAYERS IN LOBBY',
                                  style: TextStyle(
                                    fontFamily: 'Bungee',
                                    fontSize: 16,
                                    color: Color(0xFF50AFD5),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _lobbyPlayers.length,
                                itemBuilder: (context, index) {
                                  final player = _lobbyPlayers[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: Image.asset(
                                        player.avatarAsset,
                                        width: 40,
                                        height: 40,
                                      ),
                                      title: Text(
                                        player.name,
                                        style: TextStyle(
                                          fontFamily: 'Bungee',
                                          fontSize: 16,
                                          color: player.isCurrentPlayer
                                              ? const Color(0xFFF36567)
                                              : const Color(0xFF50AFD5),
                                        ),
                                      ),
                                      trailing: player.isCurrentPlayer
                                          ? const Text(
                                              'YOU',
                                              style: TextStyle(
                                                fontFamily: 'Bungee',
                                                fontSize: 12,
                                                color: Color(0xFFF36567),
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            
            // Admin message overlay
            if (_showAdminMessage)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 10, 
                right: 10, 
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF36567),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), 
                    child: Column(
                      children: [
                        const Text(
                          'ANNOUNCEMENT', 
                          style: TextStyle(
                            fontFamily: 'Bungee', 
                            fontSize: 18, 
                            color: Colors.white, 
                            letterSpacing: 1, 
                          ),
                        ), 
                        const SizedBox(height: 8), 
                        Text(
                          _adminMessage, 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(
                            fontFamily: 'Bungee', 
                            fontSize: 14, 
                            color: Colors.white, 
                            letterSpacing: 0.5, 
                          ),
                        ), 
                        const SizedBox(height: 8), 
                        GestureDetector(
                          onTap: () { 
                            setState(() { 
                              _showAdminMessage = false; 
                            }); 
                          }, 
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 8,
                            ), 
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(20),
                            ), 
                            child: const Text(
                              'DISMISS',
                              style: TextStyle(
                                fontFamily: 'Bungee', 
                                fontSize: 12, 
                                color: Color(0xFFF36567), 
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}