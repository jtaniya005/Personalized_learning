import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/page_transitions.dart';
import 'auth_choice_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  
  late final Animation<double> logoScale;
  late final Animation<double> logoFade;
  
  late final Animation<double> wordmarkFade;
  late final Animation<Offset> wordmarkSlide;
  
  late final Animation<double> taglineFade;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo entrance (0 to 600ms)
    logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    logoFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    // Wordmark entrance (450ms to 1050ms)
    wordmarkFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    );
    wordmarkSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline and Loader entrance (750ms to 1350ms)
    taglineFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
    );

    controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for BOTH the minimum splash duration (2.8s) and the first auth state
    final results = await Future.wait<dynamic>([
      FirebaseAuth.instance.authStateChanges().first,
      Future.delayed(const Duration(milliseconds: 2800)),
    ]);
    
    if (!mounted) return;
    
    final user = results[0] as User?;
    Widget nextScreen;
    
    if (user != null && user.emailVerified) {
      nextScreen = const HomeScreen(
        studentClass: 10, 
        studentName: 'Student', 
        avatarIndex: 0
      );
    } else {
      nextScreen = const AuthChoiceScreen();
    }
    
    Navigator.of(context).pushReplacement(
      FadeSlidePageRoute(page: nextScreen),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: logoFade,
                  child: ScaleTransition(
                    scale: logoScale,
                    child: const AppLogo(size: 96),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: wordmarkSlide,
                  child: FadeTransition(
                    opacity: wordmarkFade,
                    child: Text(
                      'LearnBuddy', 
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: taglineFade,
                  child: Text(
                    'Your personal AI study buddy',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: taglineFade,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.marigold,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
