import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/page_transitions.dart';
import 'login_screen.dart';
import 'class_selection_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscure = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => isLoading = true);

    // Call Backend Register API (Creates unique user ID in DB)
    final res = await AuthService.register(
      name: name,
      email: email,
      password: password,
      studentClass: 10,
    );

    setState(() => isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        // Proceed to Screen 4: Class Selection Screen
        Navigator.of(context).pushReplacement(
          FadeSlidePageRoute(
            page: ClassSelectionScreen(user: res['user']),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Registration failed')),
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
          // ── Bottom Wavy Gradient Shape ──
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WarmWaveWidget(height: 70),
          ),

          // ── Bottom Right Floral Marigold Decoration ──
          const Positioned(
            bottom: 10,
            right: -10,
            child: MarigoldFloralWidget(size: 110),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Spiral Binder Decoration (Screen 3 Header) ──
                const NotebookSpiralHeader(height: 38, ringCount: 11),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row with Sparkle
                        Row(
                          children: [
                            Text(
                              'Create Account',
                              style: GoogleFonts.fraunces(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1B18),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('✨', style: TextStyle(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          'Start make personalized\nlearning experience',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B655B),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 1. Full Name
                        _buildInputField(
                          controller: nameController,
                          hint: 'Full Name',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),

                        // 2. Email Address
                        _buildInputField(
                          controller: emailController,
                          hint: 'Email Address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // 3. Password
                        _buildInputField(
                          controller: passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: obscure,
                          onToggleObscure: () => setState(() => obscure = !obscure),
                        ),
                        const SizedBox(height: 14),

                        // 4. Confirm Password
                        _buildInputField(
                          controller: confirmPasswordController,
                          hint: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: obscureConfirm,
                          onToggleObscure: () => setState(() => obscureConfirm = !obscureConfirm),
                          onSubmitted: (_) => _handleRegister(),
                        ),
                        const SizedBox(height: 28),

                        // ── Primary Orange Gradient Pill Button ──
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEA580C).withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
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
                                        'Register',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Footer Link: Already have an account? Log In
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              FadeSlidePageRoute(page: const LoginScreen()),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: const Color(0xFF6B655B),
                                ),
                                children: const [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Log In',
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

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
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
        controller: controller,
        obscureText: isPassword && obscure,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, color: const Color(0xFF1E1B18)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF9CA3AF)),
          prefixIcon: Icon(icon, color: const Color(0xFF1E1B18), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
