import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
  final username = _usernameController.text.trim().toUpperCase();
  if (username.isNotEmpty) {
    try {
      // Store the player in Firebase
      await _authService.signInPlayer(username);
      
      // Navigate to dashboard with the username
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(currentPlayerName: username),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing in. Please try again.'),
          backgroundColor: Color(0xFF50AFD5),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter your game name pussy!'),
        backgroundColor: Color(0xFF50AFD5),
      ),
    );
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ZONE WARS',
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
                'CHECK IN BY CREATING A USERNAME BELOW',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF50AFD5),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 266,
                child: Image.asset(
                  'lib/assets/login_screen_asset.png',
                  fit: BoxFit.contain,
                  height: 266,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 179,
                height: 53,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF50AFD5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: TextField(
  controller: _usernameController,
  textAlign: TextAlign.center,
  textCapitalization: TextCapitalization.characters,
  maxLength: 10,
  maxLengthEnforcement: MaxLengthEnforcement.enforced,
  style: const TextStyle(
    fontFamily: 'Bungee',
    fontSize: 16,
    color: Color(0xFF50AFD5),
  ),
  decoration: const InputDecoration(
    hintText: 'USERNAME..',
    hintStyle: TextStyle(
      fontFamily: 'Bungee',
      fontSize: 16,
      color: Color(0xFF50AFD5),
      letterSpacing: 2,
    ),
    isDense: true,
    border: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    counterText: '',
  ),
),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _handleLogin,
                child: Container(
                  width: 179,
                  height: 53,
                  decoration: BoxDecoration(
                    color: const Color(0xFF50AFD5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                        fontFamily: 'Bungee',
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
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



/*
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ZONE WARS',
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
                'CHECK IN BY CREATING A USERNAME BELOW',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF50AFD5),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 266,
                child: Image.asset(
                  'lib/assets/login_screen_asset.png',
                  fit: BoxFit.contain,
                  height: 266,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 179,
                height: 53,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF50AFD5),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: TextField(
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Bungee',
                      fontSize: 16,
                      color: Color(0xFF50AFD5),
                    ),
                    decoration: InputDecoration(
                      hintText: 'USERNAME..',
                      hintStyle: TextStyle(
                        fontFamily: 'Bungee',
                        fontSize: 16,
                        color: Color(0xFF50AFD5),
                        letterSpacing: 2,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
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

*/
