import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'phone_otp_screen.dart';
import '../widgets/focus_glow_wrapper.dart';
import '../widgets/primary_glow_button.dart';
import '../widgets/animated_scale_press.dart';
import '../widgets/page_transitions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() => isLoading = false);
        _goHome();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) _goHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
        );
      }
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      FadeSlidePageRoute(
        page: const HomeScreen(
          studentClass: 10,
          studentName: 'Student',
          avatarIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  );
                },
                child: Row(
                  children: [
                    const AppLogo(size: 40),
                    const SizedBox(width: 10),
                    Text('Learn Buddy', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(tr(context, 'login_welcome'),
                  style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                tr(context, 'login_sub'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              NotebookCard(
                ambientGlow: true,
                holeCount: 5,
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'login_title'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FocusGlowWrapper(
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: tr(context, 'email_hint'),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FocusGlowWrapper(
                      child: TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          hintText: tr(context, 'password_hint'),
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(tr(context, 'forgot_password'),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryGlowButton(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _loginWithEmail,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(tr(context, 'auth_login')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.rule)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(tr(context, 'or_continue_with'),
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                  Expanded(child: Divider(color: AppColors.rule)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: tr(context, 'google'),
                      icon: Icons.g_mobiledata_rounded,
                      onTap: isLoading ? () {} : _loginWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialButton(
                      label: tr(context, 'phone_otp'),
                      icon: Icons.phone_android_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PhoneOtpScreen(isRegister: false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(text: tr(context, 'new_here')),
                      TextSpan(
                        text: tr(context, 'create_account_link'),
                        style: const TextStyle(
                          color: AppColors.skyInk,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: (TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              FadeSlidePageRoute(
                                  page: const RegisterScreen()),
                            );
                          }),
                      ),
                    ],
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScalePress(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: AppColors.ink),
        label: Text(label,
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(color: AppColors.rule),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
