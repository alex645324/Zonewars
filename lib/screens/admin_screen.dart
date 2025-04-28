import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/player_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'code_floor_screen.dart';
import 'admin_login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _timerMinutesController = TextEditingController(text: "3"); // Default 3 minutes
  
  List<Player> _players = [];
  String _selectedZone = 'FLOOR 2';
  bool _isLoading = true;
  StreamSubscription? _playersSubscription;
  
  // Timer related properties
  Timer? _redirectTimer;
  int _timerCountdown = 0;
  bool _timerActive = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
    _loadPlayers();
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

  Future<void> _disqualifyPlayer(String playerId) async {
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

  Future<void> _sendAnnouncement() async {
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

  // New method to start the redirection timer
  void _startRedirectTimer() {
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
  
  // Format time as mm:ss
  String _formatTime() {
    final minutes = (_timerCountdown / 60).floor();
    final seconds = _timerCountdown % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Cancel the active timer
  void _cancelTimer() {
    _redirectTimer?.cancel();
    setState(() {
      _timerActive = false;
    });
    _firestoreService.sendAdminMessage('Zone change canceled');
  }

  Future<void> _redirectAllUsers() async {
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

  @override
  void dispose() {
    _announcementController.dispose();
    _zoneController.dispose();
    _timerMinutesController.dispose();
    _playersSubscription?.cancel();
    _redirectTimer?.cancel();
    _authService.clearAdminStatus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PLAYERS',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 20,
                  color: Color(0xFF50AFD5),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
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