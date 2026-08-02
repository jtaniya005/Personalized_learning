import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool isPlaying;

  const ConfettiOverlay({super.key, required this.isPlaying});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      });
      
    if (widget.isPlaying) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles = List.generate(60, (index) => _Particle(_random));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying && !_controller.isAnimating) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_particles, 1.0 - _controller.value),
        child: Container(),
      ),
    );
  }
}

class _Particle {
  double x, y;
  double vx, vy;
  Color color;
  double size;
  double rotation;
  double vr;

  _Particle(Random random)
      : x = random.nextDouble() * 400 - 200, // Will be centered in painter
        y = random.nextDouble() * -100 - 50,
        vx = (random.nextDouble() - 0.5) * 15,
        vy = random.nextDouble() * -10 - 5,
        color = _getConfettiColor(random),
        size = random.nextDouble() * 8 + 4,
        rotation = random.nextDouble() * pi * 2,
        vr = (random.nextDouble() - 0.5) * 0.5;

  static Color _getConfettiColor(Random random) {
    const colors = [
      AppColors.marigold,
      AppColors.coral,
      AppColors.sage,
      AppColors.skyInk,
      AppColors.grape,
    ];
    return colors[random.nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;
    vy += 0.5; // gravity
    rotation += vr;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double opacity;

  _ConfettiPainter(this.particles, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    
    final center = Offset(size.width / 2, size.height / 3);
    
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
        
      canvas.save();
      canvas.translate(center.dx + p.x, center.dy + p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
