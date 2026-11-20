import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/voice_app_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? color;
  final Gradient? gradient;

  const WaveformVisualizer({
    super.key,
    this.isPlaying = true,
    this.barCount = 18,
    this.height = 36.0,
    this.color,
    this.gradient,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.animateTo(0.2, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final offset = (index / widget.barCount) * 2 * math.pi;
              final progress = _controller.value * 2 * math.pi;
              final factor = widget.isPlaying
                  ? 0.25 + 0.75 * math.pow((math.sin(progress + offset) + 1) / 2, 1.4)
                  : 0.15;
              final barHeight = math.max(4.0, widget.height * factor);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Container(
                  width: 3.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: widget.gradient ?? VoiceAppColors.purpleCyanGradient,
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: widget.isPlaying
                        ? [
                            BoxShadow(
                              color: VoiceAppColors.primaryCyan.withOpacity(0.35),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
