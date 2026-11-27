import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/page_transitions.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // ── Top Left Organic Golden Shape ──
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFDE68A).withOpacity(0.55),
                    const Color(0xFFFFFDF9).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Top Right Floral Marigold Decoration ──
          const Positioned(
            top: -10,
            right: -10,
            child: MarigoldFloralWidget(size: 140),
          ),

          // ── Bottom Left Floral Marigold Decoration ──
          const Positioned(
            bottom: 30,
            left: -15,
            child: MarigoldFloralWidget(size: 120, mirror: true),
          ),

          // ── Bottom Right Stack of Books Illustration ──
          const Positioned(
            bottom: 110,
            right: 24,
            child: StackOfBooksWidget(width: 90, height: 55),
          ),

          // ── Main Content Area ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Open Glowing Book Illustration
                  const Center(
                    child: OpenBookIllustration(size: 120),
                  ),
                  const SizedBox(height: 16),

                  // Brand Title
                  Text(
                    'Learn Buddy',
                    style: GoogleFonts.fraunces(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B18),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Your Personal Mentor\nfor Class 10 & 12',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF524C42),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Cursive Tagline
                  Text(
                    'Learn · Plan · Grow.',
                    style: GoogleFonts.caveat(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB45309),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 4),

                  // ── Action Buttons ──
                  // 1. Get Started (Dark Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        FadeSlidePageRoute(page: const RegisterScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1B18),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Login (White Pill Button)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        FadeSlidePageRoute(page: const LoginScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E1B18),
                        side: const BorderSide(color: Color(0xFFE5D5BD), width: 1.4),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Footer Link
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      FadeSlidePageRoute(page: const RegisterScreen()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF6B655B),
                        ),
                        children: const [
                          TextSpan(text: 'New here? '),
                          TextSpan(
                            text: 'Create Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
