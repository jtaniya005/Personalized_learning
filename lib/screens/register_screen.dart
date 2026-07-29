import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../widgets/app_logo.dart';
import '../models/mock_data.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'phone_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  int selectedClass = 10;
  int selectedAvatar = 0;
  bool obscure = true;
  bool obscureConfirm = true;

  void _createAccount() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          studentClass: selectedClass,
          studentName: nameController.text.trim().isEmpty
              ? 'Student'
              : nameController.text.trim(),
          avatarIndex: selectedAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogo(size: 36),
                  const SizedBox(width: 10),
                  Text('Learn Buddy', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 28),
              Text(tr(context, 'register_title'),
                  style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                tr(context, 'register_sub'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // ── Avatar picker ──
              Text(tr(context, 'pick_avatar'), style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatarOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final a = avatarOptions[i];
                    final isSelected = selectedAvatar == i;
                    return GestureDetector(
                      onTap: () => setState(() => selectedAvatar = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: a.gradient),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.ink : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: a.gradient.first.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(a.emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // ── Class selector ──
              Text(tr(context, 'which_class'),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ClassChip(
                    label: 'Class 10',
                    selected: selectedClass == 10,
                    onTap: () => setState(() => selectedClass = 10),
                  ),
                  const SizedBox(width: 12),
                  _ClassChip(
                    label: 'Class 12',
                    selected: selectedClass == 12,
                    onTap: () => setState(() => selectedClass = 12),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Form ──
              NotebookCard(
                holeCount: 6,
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'your_details'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: tr(context, 'full_name_hint'),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    TextField(
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: tr(context, 'confirm_password_hint'),
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createAccount,
                        child: Text(tr(context, 'create_account_btn')),
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
                    child: Text(tr(context, 'or_signup_with'),
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                  Expanded(child: Divider(color: AppColors.rule)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _createAccount,
                      icon: Icon(Icons.g_mobiledata_rounded,
                          size: 22, color: AppColors.ink),
                      label: Text(tr(context, 'google'),
                          style: TextStyle(
                              color: AppColors.ink, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: AppColors.rule),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PhoneOtpScreen(isRegister: true),
                        ),
                      ),
                      icon: Icon(Icons.phone_android_rounded,
                          size: 20, color: AppColors.ink),
                      label: Text(tr(context, 'phone_otp'),
                          style: TextStyle(
                              color: AppColors.ink, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: AppColors.rule),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                      TextSpan(text: tr(context, 'already_have_account')),
                      TextSpan(
                        text: tr(context, 'login_link'),
                        style: const TextStyle(
                          color: AppColors.skyInk,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: (TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()))),
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

class _ClassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ClassChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.marigold : AppColors.paperCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.marigold : AppColors.rule,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
