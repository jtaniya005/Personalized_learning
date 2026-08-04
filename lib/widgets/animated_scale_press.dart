import 'package:flutter/material.dart';

/// Wraps any widget (like a button) with a subtle scale-down effect on press.
class AnimatedScalePress extends StatefulWidget {
  final Widget child;
  
  const AnimatedScalePress({super.key, required this.child});

  @override
  State<AnimatedScalePress> createState() => _AnimatedScalePressState();
}

class _AnimatedScalePressState extends State<AnimatedScalePress> {
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
        child: widget.child,
      ),
    );
  }
}
