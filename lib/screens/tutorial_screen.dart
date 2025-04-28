import 'package:flutter/material.dart';
import 'sign_in_screen.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background diagonal patterns would be added as images
              // Number indicators would be added as positioned widgets
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 42.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'TUTORIAL',
                          textAlign: TextAlign.center,
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
                          "DON'T BE A PRICK FOLLOW THE INSTRUCTIONS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Bungee',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF50AFD5),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildInstructionItem(
                          '1. WHEN THE FLOOR',
                          'CHANGES TYPE IN THE', 
                          'NEW FLOORS CODE'
                        ),
                        const SizedBox(height: 40),
                        _buildInstructionItem(
                          '2. WHEN YOU GET HIT...',
                          'PRESS "I GOT HIT"', 
                          'BUTTON'
                        ),
                        const SizedBox(height: 40),
                        _buildInstructionItem(
                          '3. UNFOLLOW LG',
                          "ASSASSIN'S ON IG😂", 
                          ''
                        ),
                      ],
                    ),
                    
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Container(
                        width: 200,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF50AFD5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            'NEXT',
                            style: TextStyle(
                              fontFamily: 'Bungee',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF50AFD5),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String line1, String line2, String line3) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          line1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Bungee',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF50AFD5),
            letterSpacing: 2,
          ),
        ),
        Text(
          line2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Bungee',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF50AFD5),
            letterSpacing: 2,
          ),
        ),
        if (line3.isNotEmpty)
          Text(
            line3,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Bungee',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF50AFD5),
              letterSpacing: 2,
            ),
          ),
      ],
    );
  }
}