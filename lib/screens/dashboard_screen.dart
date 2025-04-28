import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'code_floor_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/player_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  final String currentPlayerName;
  
  const DashboardScreen({
    Key? key, 
    required this.currentPlayerName,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  late List<Player> players = []; // Initialize with empty list
  StreamSubscription? _playerSubscription;
  bool _showAdminMessage = false;
  String _adminMessage = '';
  StreamSubscription? _adminMessageSubscription;
  StreamSubscription? _redirectSubscription;

  @override
  void initState() {
    super.initState();
    _setupAdminMessageListener();
    _setupPlayerListener();
    _setupRedirectListener();
    // Removed _startNavigationTimer() call
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

  void _setupPlayerListener() {
  final playerId = _authService.currentPlayerId;
  print('Dashboard - Current Player ID: $playerId'); // Debug log

  // Listen to all players instead of just the current player
  _playerSubscription = _firestore
      .collection('players')
      .snapshots()
      .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          // Convert all docs to Player objects
          List<Player> allPlayers = [];
          
          for (var doc in snapshot.docs) {
            // Generate a stable "random" avatar for each player based on their ID
            final avatarNum = (doc.id.hashCode % 6) + 1; // 1-6 range
            final avatarPath = 'lib/assets/avatar$avatarNum.png';
            
            // Create player using the existing fromMap method
            Player player = Player.fromMap(
              doc.data(),
              id: doc.id,
              currentPlayerId: playerId ?? 'local',
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
            
            allPlayers.add(player);
          }
          
          // Sort the players with complex logic:
          // 1. Active players first, then disqualified
          // 2. Current player is first among active players
          // 3. Current player is first among disqualified if they're disqualified
          allPlayers.sort((a, b) {
            // First compare active/spectator status
            if (!a.isSpectator && b.isSpectator) return -1;
            if (a.isSpectator && !b.isSpectator) return 1;
            
            // If both are in same category (active or spectator)
            // and one is current player, current player gets priority
            if (a.isCurrentPlayer) return -1;
            if (b.isCurrentPlayer) return 1;
            
            // For players in the same category who aren't the current player,
            // sort alphabetically
            return a.name.compareTo(b.name);
          });
          
          setState(() {
            players = allPlayers;
          });
        } else if (playerId == null) {
          // Fallback for when there are no players in the database
          print('Warning: No players found, using local fallback'); // Debug log
          setState(() {
            players = [
              Player(
                id: 'local',
                name: widget.currentPlayerName,
                avatarAsset: 'lib/assets/avatar1.png',
                lives: 3,
                isCurrentPlayer: true,
              ),
            ];
          });
        }
      });
}

  void _setupRedirectListener() {
  _redirectSubscription = _firestore
      .collection('game_state')
      .doc('redirect')
      .snapshots()
      .listen((snapshot) async {
    if (snapshot.exists && snapshot.data()?['shouldRedirect'] == true) {
      final timestamp = snapshot.data()?['timestamp'] as Timestamp?;
      final now = Timestamp.now();
      if (timestamp != null && now.seconds - timestamp.seconds < 10) {
        final floorName = snapshot.data()?['floorName'] as String? ?? 'FLOOR 2';
        if (!mounted) return;

        // 1) clear the flag so it won't retrigger
        try {
          await _firestore
              .collection('game_state')
              .doc('redirect')
              .update({'shouldRedirect': false});
        } catch (e) {
          print('Couldn’t clear redirect flag: $e');
        }

        // 2) navigate to the code‐entry screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FloorCodeScreen(
              currentPlayerName: widget.currentPlayerName,
              floorName: floorName,
              validCodes: _firestoreService.getValidCodesForFloor(floorName),
            ),
          ),
        );
      }
    }
  });
}


  void _handleGotHit() async {
    final playerId = _authService.currentPlayerId;
    if (playerId == null) {
      print('Error: currentPlayerId is null'); // Add debug log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Player ID not found'),
          backgroundColor: Color(0xFFF36567),
        ),
      );
      return;
    }

    final currentPlayer = players.firstWhere((p) => p.isCurrentPlayer);
    if (currentPlayer.lives > 0) {
      try {
        final newLives = currentPlayer.lives - 1;
        await _firestore
            .collection('players')
            .doc(playerId) // Use the checked playerId
            .update({
          'eliminationCount': 3 - newLives,
        });

        if (newLives == 0) {
          _showDisqualificationOverlay();
        }
      } catch (e) {
        print('Error updating player status: $e'); // Add debug log
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating player status'),
            backgroundColor: Color(0xFFF36567),
          ),
        );
      }
    }
  }

  void _showDisqualificationOverlay() {
    _authService.disqualifyPlayer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DisqualificationOverlay(
        onSpectatorMode: () async {
          await _authService.enterSpectatorMode();
          if (mounted) {
            Navigator.of(context).pop();
            setState(() {
              final currentPlayer = players.firstWhere((p) => p.isCurrentPlayer);
              currentPlayer.isSpectator = true;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _redirectSubscription?.cancel();
    _playerSubscription?.cancel();
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
                    'DASHBOARD',
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
                    'WHEN YOU GET HIT PRESS THE "I GOT HIT" BUTTON IT\'S NOT THAT HARD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF50AFD5),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return PlayerListItem(
                          player: player,
                          onGotHit: player.isCurrentPlayer && !player.isSpectator 
                            ? _handleGotHit 
                            : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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

class DisqualificationOverlay extends StatelessWidget {
  final VoidCallback onSpectatorMode;

  const DisqualificationOverlay({
    Key? key,
    required this.onSpectatorMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'DISQUALIFIED',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 50,
                  color: Color(0xFFF36567),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onSpectatorMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50AFD5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'ENTER SPECTATOR MODE',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
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

class PlayerListItem extends StatelessWidget {
  final Player player;
  final VoidCallback? onGotHit;

  const PlayerListItem({
    Key? key,
    required this.player,
    this.onGotHit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: player.isSpectator ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Image.asset(
              player.avatarAsset,
              width: 60,
              height: 60,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
                    color: Color(0xFF50AFD5),
                  ),
                ),
                if (player.isSpectator)
                  const Text(
                    'SPECTATOR',
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 12,
                      color: Color(0xFFF36567),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Image.asset(
                    index < player.lives 
                      ? 'lib/assets/heart.png'
                      : 'lib/assets/Xbutton.png',
                    width: 24,
                    height: 24,
                  ),
                );
              }),
            ),
            if (player.isCurrentPlayer && !player.isSpectator)
              GestureDetector(
                onTap: onGotHit,
                child: Image.asset(
                  'lib/assets/I_got_hit_button.png',
                  width: 100,
                  height: 100,
                ),
              ),
          ],
        ),
      ),
    );
  }
}