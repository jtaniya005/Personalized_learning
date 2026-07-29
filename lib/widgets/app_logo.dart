import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Learn Buddy's mark: an open-book badge (learning) with a small spark
/// badge overlapping its corner (the "buddy" — bright, alive, present).
/// Built from layered shapes rather than a text monogram so it reads
/// as a real logo at any size, including as a future app icon.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    final sparkSize = size * 0.42;
    return SizedBox(
      width: size + sparkSize * 0.5,
      height: size + sparkSize * 0.5,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft glow behind the mark.
          Positioned(
            left: sparkSize * 0.25,
            top: sparkSize * 0.25,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.marigold.withOpacity(0.35),
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.12),
                  ),
                ],
              ),
            ),
          ),
          // Main badge — book.
          Positioned(
            left: sparkSize * 0.25,
            top: sparkSize * 0.25,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.coral, AppColors.marigold],
                ),
                borderRadius: BorderRadius.circular(size * 0.28),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: size * 0.52,
              ),
            ),
          ),
          // Spark badge — the "buddy" accent.
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: sparkSize,
              height: sparkSize,
              decoration: BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paper, width: sparkSize * 0.09),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.bolt_rounded,
                color: AppColors.marigold,
                size: sparkSize * 0.56,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
