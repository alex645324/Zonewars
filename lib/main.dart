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
