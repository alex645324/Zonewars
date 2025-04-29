import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/game_state_service.dart';
import 'screens/sign_in_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/code_floor_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_end_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB_wzXMStG-lK17dfkakSy1rHBcmm7Y90M",
      authDomain: "zonewars-70309.firebaseapp.com",
      projectId: "zonewars-70309",
      storageBucket: "zonewars-70309.firebasestorage.app",
      messagingSenderId: "62044249374",
      appId: "1:62044249374:web:49b8a989eeb7c072ccfd0f",
      measurementId: "G-4HS1KGMF72",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _disqualificationTimer;
  final GameStateService _gameStateService = GameStateService();

  @override
  void initState() {
    super.initState();
    // Initialize game state
    _gameStateService.initializeGameState();
    // Start the disqualification check timer
    _startDisqualificationTimer();
  }

  void _startDisqualificationTimer() {
    _disqualificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkAndDisqualifyPlayers();
    });
  }

  Future<void> _checkAndDisqualifyPlayers() async {
    try {
      final now = DateTime.now();
      print('Running disqualification check at ${now.toString()}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('players')
          .where('isSpectator', isEqualTo: false)
          .where('codeEntered', isEqualTo: false)
          .get();

      print('Found ${snapshot.docs.length} players who have not entered code');
      
      final batch = FirebaseFirestore.instance.batch();
      bool hasBatchOperations = false;

      for (final doc in snapshot.docs) {
        final deadline = doc.data()['codeEntryDeadline'] as Timestamp?;
        final playerName = doc.data()['name'] as String? ?? 'Unknown';
        
        if (deadline != null) {
          print('Player $playerName deadline: ${deadline.toDate().toString()}');
          print('Current time: ${now.toString()}');
          
          if (now.isAfter(deadline.toDate())) {
            print('DISQUALIFYING player ${doc.id} - $playerName - deadline passed');
            
            batch.update(doc.reference, {
              'isActive': false,
              'isSpectator': true,
              'eliminationCount': 3,
            });
            hasBatchOperations = true;
          }
        } else {
          print('Player $playerName has no deadline set');
        }
      }

      if (hasBatchOperations) {
        await batch.commit();
        print('Successfully processed disqualifications');
      }
    } catch (error) {
      print('Error in disqualification check: $error');
    }
  }

  @override
  void dispose() {
    _disqualificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Wars',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: const AppLauncher(),
    );
  }
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ZONE WARS',
              style: TextStyle(
                fontFamily: 'Bungee',
                fontSize: 60,
                fontWeight: FontWeight.w400,
                color: Color(0xFF50AFD5),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50AFD5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 24,
                ),
              ),
              child: const Text('PLAYER LOGIN'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 16,
                ),
              ),
              child: const Text(
                'ADMIN LOGIN',
                style: TextStyle(
                  color: Color(0xFFF36567),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'dart:async'; // Add this import for Timer
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/sign_in_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/code_floor_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB_wzXMStG-lK17dfkakSy1rHBcmm7Y90M",
      authDomain: "zonewars-70309.firebaseapp.com",
      projectId: "zonewars-70309",
      storageBucket: "zonewars-70309.firebasestorage.app",
      messagingSenderId: "62044249374",
      appId: "1:62044249374:web:49b8a989eeb7c072ccfd0f",
      measurementId: "G-4HS1KGMF72",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _disqualificationTimer;

  @override
  void initState() {
    super.initState();
    // Start the disqualification check timer
    _startDisqualificationTimer();
  }

  void _startDisqualificationTimer() {
    _disqualificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final now = DateTime.now();
      print('Running disqualification check at ${now.toString()}');
      
      FirebaseFirestore.instance
          .collection('players')
          .where('isSpectator', isEqualTo: false)
          .where('codeEntered', isEqualTo: false)
          .get()
          .then((snapshot) {
            print('Found ${snapshot.docs.length} players who have not entered code');
            
            for (final doc in snapshot.docs) {
              final deadline = doc.data()['codeEntryDeadline'] as Timestamp?;
              final playerName = doc.data()['name'] as String? ?? 'Unknown';
              
              if (deadline != null) {
                print('Player $playerName deadline: ${deadline.toDate().toString()}');
                print('Current time: ${now.toString()}');
                
                if (now.isAfter(deadline.toDate())) {
                  print('DISQUALIFYING player ${doc.id} - $playerName - deadline passed');
                  
                  // Use a direct document reference to ensure update happens
                  FirebaseFirestore.instance
                      .collection('players')
                      .doc(doc.id)
                      .update({
                        'isActive': false,
                        'isSpectator': true,
                        'eliminationCount': 3,
                      })
                      .then((_) => print('Successfully disqualified $playerName'))
                      .catchError((e) => print('Error disqualifying $playerName: $e'));
                }
              } else {
                print('Player $playerName has no deadline set');
              }
            }
          })
          .catchError((error) {
            print('Error in disqualification check: $error');
          });
    });
  }

  @override
  void dispose() {
    _disqualificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Wars',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: const AppLauncher(),
    );
  }
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ZONE WARS',
              style: TextStyle(
                fontFamily: 'Bungee',
                fontSize: 60,
                fontWeight: FontWeight.w400,
                color: Color(0xFF50AFD5),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50AFD5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 24,
                ),
              ),
              child: const Text('PLAYER LOGIN'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 16,
                ),
              ),
              child: const Text(
                'ADMIN LOGIN',
                style: TextStyle(
                  color: Color(0xFFF36567),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/


