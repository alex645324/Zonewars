import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../services/auth_service.dart';
import '../screens/dashboard_screen.dart' show DashboardScreen, DisqualificationOverlay;

class FloorCodeScreen extends StatefulWidget {
  final String currentPlayerName;
  
  const FloorCodeScreen({
    Key? key, 
    required this.currentPlayerName,
  }) : super(key: key);

  @override
  State<FloorCodeScreen> createState() => _FloorCodeScreenState();
}

class _FloorCodeScreenState extends State<FloorCodeScreen> {
  final List<String> validCodes = ['F2C1', 'F2C2', 'F2C3', 'F2C4'];
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() async {
    try {
      // Disqualify the player
      await _authService.disqualifyPlayer();
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DisqualificationOverlay(
            onSpectatorMode: () async {
              await _authService.enterSpectatorMode();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(
                      currentPlayerName: widget.currentPlayerName,
                    ),
                  ),
                );
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating player status'),
            backgroundColor: Color(0xFFF36567),
          ),
        );
      }
    }
  }

  String _formatTime() {
    final minutes = (_countdown / 60).floor();
    final seconds = _countdown % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleCodeSubmission(String code) async {
    final submittedCode = code.trim().toUpperCase();
    if (submittedCode.isNotEmpty) {
      try {
        if (validCodes.contains(submittedCode)) {
          // Valid code entered
          await _authService.updatePlayerZoneCode(submittedCode);
          _timer?.cancel();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code accepted!'),
                backgroundColor: Colors.green,
              ),
            );
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  currentPlayerName: widget.currentPlayerName,
                ),
              ),
            );
          }
        } else {
          // Invalid code entered
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wrong code dumbass! Are you slow the code is by the elevator.'),
              backgroundColor: Color(0xFFF36567),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error submitting code'),
              backgroundColor: Color(0xFFF36567),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'FLOOR SCAN',
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
                'TYPE IN THE CODE BEFORE THE TIMER RUNS OUT OR GET DISQUALIFIED',
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
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.8,
                  ),
                  children: [
                    TextSpan(
                      text: 'NEW ZONE IS ',
                      style: TextStyle(
                        color: Color(0xFF50AFD5),
                      ),
                    ),
                    TextSpan(
                      text: 'FLOOR 2',
                      style: TextStyle(
                        color: Color(0xFFF36567),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'CODES ARE NEAR THE ELEVATORS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF50AFD5),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _formatTime(),
                style: const TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF50AFD5),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 180,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF50AFD5),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
                    color: Color(0xFF50AFD5),
                  ),
                  onSubmitted: _handleCodeSubmission,
                  decoration: const InputDecoration(
                    hintText: 'TYPE CODE HERE',
                    hintStyle: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 14,
                      color: Color(0xFF50AFD5),
                      letterSpacing: 0.8,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
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