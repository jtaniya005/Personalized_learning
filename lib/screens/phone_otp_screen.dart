import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import 'home_screen.dart';

/// UI-only phone + OTP flow. Wire to Firebase Auth / your SMS provider
/// on the backend — this just demonstrates the two steps and the look.
class PhoneOtpScreen extends StatefulWidget {
  final bool isRegister;
  const PhoneOtpScreen({super.key, required this.isRegister});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  bool otpSent = false;
  final phoneController = TextEditingController();
  final List<TextEditingController> otpControllers =
      List.generate(4, (_) => TextEditingController());

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(
          studentClass: 10,
          studentName: 'Alex',
          avatarIndex: 3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otpSent ? tr(context, 'enter_code') : tr(context, 'verify_phone'),
                style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              otpSent
                  ? 'We sent a 4-digit code to ${phoneController.text.isEmpty ? 'your number' : phoneController.text}.'
                  : widget.isRegister
                      ? "We'll text you a code to confirm it's you."
                      : "We'll text you a code to log you in.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            if (!otpSent) ...[
              NotebookCard(
                holeCount: 4,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => otpSent = true),
                  child: Text(tr(context, 'send_code')),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) {
                  return SizedBox(
                    width: 62,
                    child: TextField(
                      controller: otpControllers[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 22),
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goHome,
                  child: Text(tr(context, 'verify_continue')),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => otpSent = false),
                  child: Text(tr(context, 'resend'),
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
