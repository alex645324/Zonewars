import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/game_state_service.dart';
import 'lobby_screen.dart';

class GameEndScreen extends StatefulWidget {
  final String currentPlayerName;
  
  const GameEndScreen({
    Key? key, 
    required this.currentPlayerName,
  }) : super(key: key);

  @override
  State<GameEndScreen> createState() => _GameEndScreenState();
}

class _GameEndScreenState extends State<GameEndScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final GameStateService _gameStateService = GameStateService();
  
  List<Player> _activePlayers = [];
  List<Player> _spectators = [];
  bool _isLoading = true;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _gameStateSubscription;
  StreamSubscription? _redirectSubscription;
  Map<String, dynamic> _gameState = {};
  
  @override
  void initState() {
    super.initState();
    _setupGameStateListener();
    _setupPlayerListener();
    _setupRedirectListener();
  }

  void _setupGameStateListener() {
    _gameStateSubscription = _gameStateService.gameStateStream().listen((gameState) {
      setState(() {
        _gameState = gameState;
      });
      
      // If game state goes back to lobby, navigate to lobby screen
      if (gameState['status'] == GameStateService.LOBBY && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
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
      final List<Player> survivors = [];
      final List<Player> eliminated = [];
      
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
        
        if (player.isSpectator || player.lives <= 0) {
          eliminated.add(player);
        } else {
          survivors.add(player);
        }
      }
      
      // Sort winners by name (but current player first)
      survivors.sort((a, b) {
        if (a.isCurrentPlayer) return -1;
        if (b.isCurrentPlayer) return 1;
        return a.name.compareTo(b.name);
      });
      
      // Sort eliminated by name (but current player first)
      eliminated.sort((a, b) {
        if (a.isCurrentPlayer) return -1;
        if (b.isCurrentPlayer) return 1;
        return a.name.compareTo(b.name);
      });
      
      setState(() {
        _activePlayers = survivors;
        _spectators = eliminated;
        _isLoading = false;
      });
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
          snapshot.data()?['targetScreen'] == 'lobby') {
        
        // Navigate to lobby
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LobbyScreen(
                currentPlayerName: widget.currentPlayerName,
              ),
            ),
          );
        }
      }
    });
  }

  void _handleJoinNextGame() async {
    await _firestore
        .collection('players')
        .doc(_authService.currentPlayerId)
        ?.update({
          'isActive': true,
          'isSpectator': false,
          'eliminationCount': 0,
        });
        
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            currentPlayerName: widget.currentPlayerName,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _playersSubscription?.cancel();
    _gameStateSubscription?.cancel();
    _redirectSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentPlayerWinner = _activePlayers.any((p) => p.isCurrentPlayer);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontFamily: 'Bungee',
                        fontSize: 50,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF50AFD5),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Winners section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFF36567)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'WINNERS',
                            style: TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 24,
                              color: Color(0xFFF36567),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _activePlayers.isEmpty
                              ? const Text(
                                  'NO SURVIVORS',
                                  style: TextStyle(
                                    fontFamily: 'Bungee',
                                    fontSize: 18,
                                    color: Color(0xFF50AFD5),
                                  ),
                                )
                              : Column(
                                  children: _activePlayers
                                      .map((player) => ListTile(
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
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(
                                                player.lives,
                                                (index) => Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                  child: Image.asset(
                                                    'lib/assets/heart.png',
                                                    width: 24,
                                                    height: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Personal result
                    Text(
                      isCurrentPlayerWinner ? 'YOU SURVIVED!' : 'BETTER LUCK NEXT TIME!',
                      style: TextStyle(
                        fontFamily: 'Bungee',
                        fontSize: 22,
                        color: isCurrentPlayerWinner
                            ? const Color(0xFFF36567)
                            : const Color(0xFF50AFD5),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Eliminated players
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'ELIMINATED',
                            style: TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 18,
                              color: Color(0xFF50AFD5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          Expanded(
                            child: _spectators.isEmpty
                                ? const Center(
                                    child: Text(
                                      'NO ELIMINATED PLAYERS',
                                      style: TextStyle(
                                        fontFamily: 'Bungee',
                                        fontSize: 14,
                                        color: Color(0xFF50AFD5),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _spectators.length,
                                    itemBuilder: (context, index) {
                                      final player = _spectators[index];
                                      return ListTile(
                                        leading: Image.asset(
                                          player.avatarAsset,
                                          width: 30,
                                          height: 30,
                                        ),
                                        title: Text(
                                          player.name,
                                          style: TextStyle(
                                            fontFamily: 'Bungee',
                                            fontSize: 14,
                                            color: player.isCurrentPlayer
                                                ? const Color(0xFFF36567)
                                                : const Color(0xFF50AFD5),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Join next game button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleJoinNextGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF36567),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'JOIN NEXT GAME',
                          style: TextStyle(
                            fontFamily: 'Bungee',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}