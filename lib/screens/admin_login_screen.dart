import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final password = _passwordController.text.trim();
    
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the admin password'),
          backgroundColor: Color(0xFFF36567),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isAuthenticated = await _authService.authenticateAdmin(password);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AdminScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect password'),
              backgroundColor: Color(0xFFF36567),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error'),
            backgroundColor: Color(0xFFF36567),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ADMIN LOGIN',
                style: TextStyle(
                  fontFamily: 'Bungee',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF36567),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF50AFD5),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter admin password',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator(
                      color: Color(0xFF50AFD5),
                    )
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF50AFD5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Bungee',
                          fontSize: 18,
                        ),
                      ),
                      child: const Text('LOGIN'),
                    ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'BACK TO PLAYER LOGIN',
                  style: TextStyle(
                    fontFamily: 'Bungee',
                    fontSize: 16,
                    color: Color(0xFF50AFD5),
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
