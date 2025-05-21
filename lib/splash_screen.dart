import 'package:flutter/material.dart';
import 'dart:async';
import 'match_setup_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simple timer to navigate to next screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MatchSetupPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image with reduced opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.4, // Reduced opacity for background
              child: Image.asset(
                'asset/icon/25113595_3991.png', // Your "Cricket Fever" image
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title
                const Text(
                  "CRICKET SCORER",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 3.0,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  "Professional Match Scoring Solution",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
