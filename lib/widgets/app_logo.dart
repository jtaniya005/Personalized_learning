import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Learn Buddy's mark: an open-book badge (learning) with a small spark
/// badge overlapping its corner (the "buddy" — bright, alive, present).
/// Rendered using the provided SVG asset.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/learnbuddy_appicon.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
