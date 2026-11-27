import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ───────────────────────────────────────────────────────────
/// THEME DECORATIONS & ILLUSTRATIONS
/// Pixel-perfect vector implementations of the Marigold flower,
/// notebook spiral rings, warm wavy backgrounds, glowing book,
/// Buddy AI mentor mascot, dashed upload box, and circular gauge.
/// ───────────────────────────────────────────────────────────

/// 1. Marigold Flower with green leaves corner decoration
class MarigoldFloralWidget extends StatelessWidget {
  final double size;
  final bool mirror;

  const MarigoldFloralWidget({super.key, this.size = 110, this.mirror = false});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(mirror ? -1.0 : 1.0, 1.0),
      child: CustomPaint(
        size: Size(size, size),
        painter: _MarigoldFloralPainter(),
      ),
    );
  }
}

class _MarigoldFloralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Green Leaves ---
    final leafPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..style = PaintingStyle.fill;
    final leafLight = Paint()
      ..color = const Color(0xFF6B9B73)
      ..style = PaintingStyle.fill;

    void drawLeaf(double cx, double cy, double angle, double scale) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.scale(scale);

      final p = Path();
      p.moveTo(0, 0);
      p.quadraticBezierTo(12, -22, 28, -28);
      p.quadraticBezierTo(24, -10, 0, 0);
      canvas.drawPath(p, leafPaint);

      final p2 = Path();
      p2.moveTo(0, 0);
      p2.quadraticBezierTo(-12, -22, -28, -28);
      p2.quadraticBezierTo(-24, -10, 0, 0);
      canvas.drawPath(p2, leafLight);

      canvas.restore();
    }

    drawLeaf(w * 0.72, h * 0.28, -0.6, 1.1);
    drawLeaf(w * 0.52, h * 0.18, -1.2, 0.9);
    drawLeaf(w * 0.82, h * 0.58, 0.4, 0.8);
    drawLeaf(w * 0.45, h * 0.65, 1.5, 0.85);

    // --- Main Marigold Flower ---
    _drawFlower(canvas, Offset(w * 0.68, h * 0.46), w * 0.38);

    // --- Secondary Small Bud/Flower ---
    _drawFlower(canvas, Offset(w * 0.32, h * 0.28), w * 0.22);
  }

  void _drawFlower(Canvas canvas, Offset center, double radius) {
    const petalCount = 14;
    const step = (2 * math.pi) / petalCount;

    // Layer 1: Outer Orange Petals
    final pOrange = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < petalCount; i++) {
      final a = i * step;
      final px = center.dx + math.cos(a) * (radius * 0.75);
      final py = center.dy + math.sin(a) * (radius * 0.75);
      canvas.drawCircle(Offset(px, py), radius * 0.32, pOrange);
    }

    // Layer 2: Middle Golden Yellow Petals
    final pYellow = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < petalCount; i++) {
      final a = i * step + (step / 2);
      final px = center.dx + math.cos(a) * (radius * 0.55);
      final py = center.dy + math.sin(a) * (radius * 0.55);
      canvas.drawCircle(Offset(px, py), radius * 0.26, pYellow);
    }

    // Layer 3: Inner Deep Marigold / Amber Petals
    final pAmber = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final a = i * (2 * math.pi / 8);
      final px = center.dx + math.cos(a) * (radius * 0.32);
      final py = center.dy + math.sin(a) * (radius * 0.32);
      canvas.drawCircle(Offset(px, py), radius * 0.2, pAmber);
    }

    // Flower Center: Deep Warm Core
    final pCore = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.18, pCore);

    final pHighlight = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + const Offset(-1.5, -1.5), radius * 0.08, pHighlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Warm Wavy Gradient at Screen Bottoms
class WarmWaveWidget extends StatelessWidget {
  final double height;

  const WarmWaveWidget({super.key, this.height = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _WarmWavePainter(),
      ),
    );
  }
}

class _WarmWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Soft Golden Back Wave
    final pBack = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.quadraticBezierTo(w * 0.25, h * 0.1, w * 0.6, h * 0.5);
    path1.quadraticBezierTo(w * 0.85, h * 0.85, w, h * 0.3);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, pBack);

    // Layer 2: Vibrant Orange Foreground Wave
    final pFront = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path();
    path2.moveTo(0, h * 0.7);
    path2.quadraticBezierTo(w * 0.35, h * 0.95, w * 0.7, h * 0.6);
    path2.quadraticBezierTo(w * 0.88, h * 0.4, w, h * 0.55);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, pFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Notebook Spiral Header Rings for Create Account
class NotebookSpiralHeader extends StatelessWidget {
  final double height;
  final int ringCount;

  const NotebookSpiralHeader({super.key, this.height = 36, this.ringCount = 10});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _NotebookSpiralPainter(ringCount: ringCount),
      ),
    );
  }
}

class _NotebookSpiralPainter extends CustomPainter {
  final int ringCount;
  _NotebookSpiralPainter({required this.ringCount});

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / (ringCount + 1);

    final holePaint = Paint()..color = const Color(0xFFE5D5BA);
    final ringPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= ringCount; i++) {
      final x = step * i;
      // Hole punch
      canvas.drawCircle(Offset(x, size.height * 0.65), 5.5, holePaint);

      // Shadow under loop
      canvas.drawLine(Offset(x - 1, 2), Offset(x - 1, size.height * 0.65), shadowPaint);

      // Metal ring loop
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.65), ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Open Glowing Book Illustration for Landing Screen
class OpenBookIllustration extends StatelessWidget {
  final double size;

  const OpenBookIllustration({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OpenBookPainter(),
      ),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.55);

    // Sparkle star on top of book
    final starPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final starCenter = Offset(w * 0.5, h * 0.16);
    final starPath = Path();
    starPath.moveTo(starCenter.dx, starCenter.dy - 12);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx + 12, starCenter.dy);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx, starCenter.dy + 12);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx - 12, starCenter.dy);
    starPath.quadraticBezierTo(starCenter.dx, starCenter.dy, starCenter.dx, starCenter.dy - 12);
    canvas.drawPath(starPath, starPaint);

    // Dark outline style
    final outlinePaint = Paint()
      ..color = const Color(0xFF1E1B18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillGold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bookW = w * 0.78;
    final bookH = h * 0.52;

    // Left Page
    final leftPath = Path();
    leftPath.moveTo(center.dx, center.dy + bookH * 0.4);
    leftPath.quadraticBezierTo(center.dx - bookW * 0.25, center.dy + bookH * 0.5, center.dx - bookW * 0.5, center.dy + bookH * 0.35);
    leftPath.lineTo(center.dx - bookW * 0.5, center.dy - bookH * 0.38);
    leftPath.quadraticBezierTo(center.dx - bookW * 0.25, center.dy - bookH * 0.22, center.dx, center.dy - bookH * 0.35);
    leftPath.close();

    canvas.drawPath(leftPath, fillGold);
    canvas.drawPath(leftPath, outlinePaint);

    // Right Page
    final rightPath = Path();
    rightPath.moveTo(center.dx, center.dy + bookH * 0.4);
    rightPath.quadraticBezierTo(center.dx + bookW * 0.25, center.dy + bookH * 0.5, center.dx + bookW * 0.5, center.dy + bookH * 0.35);
    rightPath.lineTo(center.dx + bookW * 0.5, center.dy - bookH * 0.38);
    rightPath.quadraticBezierTo(center.dx + bookW * 0.25, center.dy - bookH * 0.22, center.dx, center.dy - bookH * 0.35);
    rightPath.close();

    canvas.drawPath(rightPath, fillGold);
    canvas.drawPath(rightPath, outlinePaint);

    // Spine Center Line
    canvas.drawLine(
      Offset(center.dx, center.dy - bookH * 0.35),
      Offset(center.dx, center.dy + bookH * 0.4),
      outlinePaint,
    );

    // Subtle page lines
    final pageLinePaint = Paint()
      ..color = const Color(0xFFD97706).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - bookW * 0.38, center.dy - bookH * 0.08),
      Offset(center.dx - bookW * 0.12, center.dy - bookH * 0.02),
      pageLinePaint,
    );
    canvas.drawLine(
      Offset(center.dx - bookW * 0.38, center.dy + bookH * 0.12),
      Offset(center.dx - bookW * 0.12, center.dy + bookH * 0.18),
      pageLinePaint,
    );

    canvas.drawLine(
      Offset(center.dx + bookW * 0.12, center.dy - bookH * 0.02),
      Offset(center.dx + bookW * 0.38, center.dy - bookH * 0.08),
      pageLinePaint,
    );
    canvas.drawLine(
      Offset(center.dx + bookW * 0.12, center.dy + bookH * 0.18),
      Offset(center.dx + bookW * 0.38, center.dy + bookH * 0.12),
      pageLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Stack of 2 Books on Landing Screen bottom right
class StackOfBooksWidget extends StatelessWidget {
  final double width;
  final double height;

  const StackOfBooksWidget({super.key, this.width = 90, this.height = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _StackOfBooksPainter(),
      ),
    );
  }
}

class _StackOfBooksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bottom Book (Green)
    _drawIsometricBook(
      canvas,
      rect: Rect.fromLTWH(w * 0.05, h * 0.45, w * 0.9, h * 0.45),
      color: const Color(0xFF4A7C59),
      pagesColor: const Color(0xFFFDFBF7),
    );

    // Top Book (Orange)
    _drawIsometricBook(
      canvas,
      rect: Rect.fromLTWH(w * 0.15, h * 0.1, w * 0.78, h * 0.42),
      color: const Color(0xFFEA580C),
      pagesColor: const Color(0xFFFDFBF7),
    );
  }

  void _drawIsometricBook(Canvas canvas, {required Rect rect, required Color color, required Color pagesColor}) {
    final p = Path();
    const r = 6.0;
    p.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(r)));
    canvas.drawPath(p, Paint()..color = color);

    // Book spine / pages strip
    final pagesPath = Path();
    pagesPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + rect.width * 0.15, rect.top + rect.height * 0.2, rect.width * 0.78, rect.height * 0.6),
      const Radius.circular(3),
    ));
    canvas.drawPath(pagesPath, Paint()..color = pagesColor);

    // Border line
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(r)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Sunburst Rays for Login Screen
class SunburstWidget extends StatelessWidget {
  final double size;

  const SunburstWidget({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SunburstPainter(),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rayPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.85;
    final cy = size.height * 0.15;

    final rayLengths = [18.0, 24.0, 16.0, 22.0, 15.0];
    final angles = [math.pi * 0.65, math.pi * 0.8, math.pi * 0.95, math.pi * 1.1, math.pi * 1.25];

    for (int i = 0; i < angles.length; i++) {
      final a = angles[i];
      final len = rayLengths[i];
      final start = Offset(cx + math.cos(a) * 12, cy + math.sin(a) * 12);
      final end = Offset(cx + math.cos(a) * (12 + len), cy + math.sin(a) * (12 + len));
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. Buddy AI Robot Mascot with Book
class BuddyMascotWidget extends StatelessWidget {
  final double size;

  const BuddyMascotWidget({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BuddyMascotPainter(),
      ),
    );
  }
}

class _BuddyMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final whitePaint = Paint()..color = Colors.white;
    final darkOutline = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final orangePaint = Paint()..color = const Color(0xFFF59E0B);
    final darkFace = Paint()..color = const Color(0xFF262626);

    // Antenna
    canvas.drawLine(Offset(w * 0.5, h * 0.28), Offset(w * 0.5, h * 0.16), darkOutline);
    canvas.drawCircle(Offset(w * 0.5, h * 0.14), 4.5, orangePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.14), 4.5, darkOutline);

    // Orange Headphone Band & Earcups
    final earL = Offset(w * 0.22, h * 0.44);
    final earR = Offset(w * 0.78, h * 0.44);
    canvas.drawCircle(earL, 8.5, orangePaint);
    canvas.drawCircle(earL, 8.5, darkOutline);
    canvas.drawCircle(earR, 8.5, orangePaint);
    canvas.drawCircle(earR, 8.5, darkOutline);

    // Head (Rounded Capsule)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.44), width: w * 0.54, height: h * 0.4),
      const Radius.circular(22),
    );
    canvas.drawRRect(headRect, whitePaint);
    canvas.drawRRect(headRect, darkOutline);

    // Eyes (Two dark dots)
    canvas.drawCircle(Offset(w * 0.42, h * 0.42), 3.4, darkFace);
    canvas.drawCircle(Offset(w * 0.58, h * 0.42), 3.4, darkFace);

    // Happy Smile
    final smilePath = Path();
    smilePath.moveTo(w * 0.45, h * 0.48);
    smilePath.quadraticBezierTo(w * 0.5, h * 0.53, w * 0.55, h * 0.48);
    canvas.drawPath(smilePath, darkOutline..strokeWidth = 2.0);

    // Cute pink cheeks
    final blushPaint = Paint()..color = const Color(0xFFFCA5A5).withOpacity(0.8);
    canvas.drawCircle(Offset(w * 0.35, h * 0.46), 3.0, blushPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.46), 3.0, blushPaint);

    // Open Book in Hands
    final bookCenter = Offset(w * 0.5, h * 0.76);
    final bookW = w * 0.6;
    final bookH = h * 0.26;

    final bookPath = Path();
    bookPath.moveTo(bookCenter.dx, bookCenter.dy - bookH * 0.2);
    bookPath.lineTo(bookCenter.dx - bookW * 0.48, bookCenter.dy - bookH * 0.5);
    bookPath.lineTo(bookCenter.dx - bookW * 0.48, bookCenter.dy + bookH * 0.4);
    bookPath.quadraticBezierTo(
      bookCenter.dx - bookW * 0.25, bookCenter.dy + bookH * 0.55,
      bookCenter.dx, bookCenter.dy + bookH * 0.3,
    );
    bookPath.quadraticBezierTo(
      bookCenter.dx + bookW * 0.25, bookCenter.dy + bookH * 0.55,
      bookCenter.dx + bookW * 0.48, bookCenter.dy + bookH * 0.4,
    );
    bookPath.lineTo(bookCenter.dx + bookW * 0.48, bookCenter.dy - bookH * 0.5);
    bookPath.close();

    canvas.drawPath(bookPath, orangePaint);
    canvas.drawPath(bookPath, darkOutline..strokeWidth = 2.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 8. Dashed Border Box for File Upload (Screen 6)
class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;
  final Color? backgroundColor;

  const DashedBorderBox({
    super.key,
    required this.child,
    this.color = const Color(0xFFD8C8B4),
    this.strokeWidth = 1.6,
    this.gap = 5.0,
    this.dash = 6.0,
    this.radius = 16.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        gap: gap,
        dash: dash,
        radius: radius,
        backgroundColor: backgroundColor,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;
  final Color? backgroundColor;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.radius,
    this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    if (backgroundColor != null) {
      canvas.drawRRect(rrect, Paint()..color = backgroundColor!);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    double currentDistance = 0.0;

    while (currentDistance < totalLength) {
      final nextDistance = currentDistance + dash;
      final extractPath = metrics.extractPath(currentDistance, math.min(nextDistance, totalLength));
      canvas.drawPath(extractPath, paint);
      currentDistance = nextDistance + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 9. Circular Percentage Ring Gauge (Screen 7)
class CircularPercentGauge extends StatelessWidget {
  final double percentage; // e.g. 86.5
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  const CircularPercentGauge({
    super.key,
    required this.percentage,
    this.size = 110,
    this.strokeWidth = 9.0,
    this.progressColor = const Color(0xFF10B981), // Emerald green arc
    this.trackColor = const Color(0xFFF3EDE2),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularPercentPainter(
          percentage: percentage,
          strokeWidth: strokeWidth,
          progressColor: progressColor,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _CircularPercentPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _CircularPercentPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage.clamp(0.0, 100.0) / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
