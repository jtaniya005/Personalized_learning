import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'phone_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;

  void _goHome() {
    // Returning user — class comes from their saved profile, not asked again.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(
          studentClass: 10,
          studentName: 'Alex',
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
              Row(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(width: 10),
                  Text('Learn Buddy', style: Theme.of(context).textTheme.titleMedium),
                ],
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
                holeCount: 5,
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'login_title'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: tr(context, 'email_hint'),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
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
                      child: ElevatedButton(
                        onPressed: _goHome,
                        child: Text(tr(context, 'auth_login')),
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
                      onTap: _goHome,
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
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: AppColors.ink),
      label: Text(label,
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: BorderSide(color: AppColors.rule),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
