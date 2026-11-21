import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Adds a subtle ambient marigold glow and an animated press scale/glow to primary buttons.
class PrimaryGlowButton extends StatefulWidget {
  final Widget child;
  
  const PrimaryGlowButton({super.key, required this.child});

  @override
  State<PrimaryGlowButton> createState() => _PrimaryGlowButtonState();
}

class _PrimaryGlowButtonState extends State<PrimaryGlowButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.marigold.withOpacity(_isPressed ? 0.4 : 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              )
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
