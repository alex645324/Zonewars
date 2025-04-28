import 'package:flutter/material.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/sign_in_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/code_floor_screen.dart';
import 'screens/dashboard_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Wars',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: const LoginScreen(),
    );
  }
}
*/