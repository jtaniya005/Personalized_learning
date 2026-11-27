import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/page_transitions.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'student_details_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool isLoading = false;
  bool rememberMe = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    // 1. First attempt Backend Direct Login (Local DB / JWT)
    final backendRes = await AuthService.login(email: email, password: password);
    if (backendRes['success'] == true) {
      if (mounted) {
        setState(() => isLoading = false);
        final user = backendRes['user'] as Map<String, dynamic>;
        _routeAfterLogin(user);
      }
      return;
    }

    // 2. Fallback to Firebase Auth
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() => isLoading = false);
        final profile = await AuthService.getProfile();
        _routeAfterLogin(profile ?? {'email': email, 'name': cred.user?.displayName ?? 'Student'});
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(backendRes['message'] ?? e.message ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(backendRes['message'] ?? 'Error: ${e.toString()}')),
        );
      }
    }
  }

  void _routeAfterLogin(Map<String, dynamic> user) async {
    final marksheetData = user['marksheet_data'] as Map?;
    final hasCompletedMarksheet = marksheetData != null && marksheetData.isNotEmpty;
    final hasSchool = user['school'] != null && user['school'].toString().trim().isNotEmpty;
    final hasSubjects = user['subjects'] != null && (user['subjects'] as List).isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    final hasLocalOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

    if (hasCompletedMarksheet || hasSchool || hasSubjects || hasLocalOnboarding) {
      await prefs.setBool('has_completed_onboarding', true);
      if (!mounted) return;
      // Direct to Dashboard
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(
          page: HomeScreen(
            studentClass: user['student_class'] as int? ?? 10,
            studentName: user['name'] ?? 'Student',
            avatarIndex: user['avatar_index'] as int? ?? 0,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      // Step 2 & 3: Details & Marksheet Screen
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(
          page: StudentDetailsScreen(initialUser: user),
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        final profile = await AuthService.getProfile();
        _routeAfterLogin(profile ?? {'email': cred.user?.email, 'name': cred.user?.displayName ?? 'Student'});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // ── Top Right Sunburst Decoration ──
          const Positioned(
            top: 20,
            right: 15,
            child: SunburstWidget(size: 80),
          ),

          // ── Bottom Wavy Gradient Shape ──
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WarmWaveWidget(height: 60),
          ),

          // ── Form Content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Arrow Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E1B18)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),

                  // Title: Welcome Back!
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B18),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Continue your learning journey\nwith Learn Buddy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B655B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Input 1: Email or Student ID
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8DECF), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E1B18).withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emailController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _loginWithEmail(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: const Color(0xFF1E1B18)),
                      decoration: InputDecoration(
                        hintText: 'Email or Student ID',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF1E1B18), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input 2: Password
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8DECF), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E1B18).withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loginWithEmail(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: const Color(0xFF1E1B18)),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1E1B18), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Remember me & Forgot Password Row
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: rememberMe,
                          activeColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.4),
                          onChanged: (v) => setState(() => rememberMe = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Primary Button: Log In ➔
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _loginWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1B18),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Log In',
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
                  const SizedBox(height: 22),

                  // "or" Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE5D5BD), thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE5D5BD), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE8DECF), width: 1.2),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              'G',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1B18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Link: New student? Create Account
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        FadeSlidePageRoute(page: const RegisterScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF6B655B),
                          ),
                          children: const [
                            TextSpan(text: 'New student? '),
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
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
