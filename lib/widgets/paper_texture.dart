import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Faint horizontal rule lines across the background, like notebook
/// paper — kept low-opacity so it reads as texture, not decoration.
class PaperTexture extends StatelessWidget {
  final Widget child;
  const PaperTexture({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _RulesPainter()),
        ),
        child,
      ],
    );
  }
}

class _RulesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rule.withOpacity(0.35)
      ..strokeWidth = 1;
    const gap = 34.0;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
