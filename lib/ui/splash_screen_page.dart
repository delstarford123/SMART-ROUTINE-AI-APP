import 'package:flutter/material.dart';
import 'home_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    // 1. Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // 2. Safety check to ensure the widget is still active
    if (!mounted) return;

    // 3. Smoothly fade into the HomePage (and remove Splash from back-button history)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(
          milliseconds: 800,
        ), // 0.8 second fade
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Navy Blue fallback
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash_bg.png', // 🔥 Ensure this file exists in your assets!
          fit: BoxFit.cover, // This forces the image to fill the entire screen
        ),
      ),
    );
  }
}
