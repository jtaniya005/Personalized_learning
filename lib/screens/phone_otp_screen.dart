import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneOtpScreen extends StatefulWidget {
  final bool isRegister;
  const PhoneOtpScreen({super.key, required this.isRegister});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  bool otpSent = false;
  bool isLoading = false;
  String? _verificationId;
  final phoneController = TextEditingController();
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController()); // Firebase OTP is 6 digits

  @override
  void dispose() {
    phoneController.dispose();
    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(
          studentClass: 10,
          studentName: 'Student',
          avatarIndex: 0,
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            setState(() => isLoading = false);
            _goHome();
          }
        } catch (e) {
          if (mounted) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Auto-verification failed: ${e.toString()}')),
            );
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            isLoading = false;
            otpSent = true;
            _verificationId = verificationId;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    final code = otpControllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        setState(() => isLoading = false);
        _goHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid code')),
        );
      }
    }
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
                  ? 'We sent a 6-digit code to ${phoneController.text.isEmpty ? 'your number' : phoneController.text}.'
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
                  onPressed: isLoading ? null : _sendOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(tr(context, 'send_code')),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 45,
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
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          FocusScope.of(context).nextFocus();
                        } else if (val.isEmpty && i > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(tr(context, 'verify_continue')),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    otpSent = false;
                    for (var c in otpControllers) {
                      c.clear();
                    }
                  }),
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
