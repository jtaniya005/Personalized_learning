import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps a TextField and adds a soft marigold glow when focused.
class FocusGlowWrapper extends StatefulWidget {
  final Widget child;
  
  const FocusGlowWrapper({super.key, required this.child});

  @override
  State<FocusGlowWrapper> createState() => _FocusGlowWrapperState();
}

class _FocusGlowWrapperState extends State<FocusGlowWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (mounted) {
          setState(() => _isFocused = hasFocus);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.marigold.withOpacity(0.3),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}
