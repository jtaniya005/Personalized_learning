import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/voice_assistant_controller.dart';
import '../theme/voice_app_theme.dart';

class AnimatedMicButton extends StatefulWidget {
  final AssistantState state;
  final double amplitude;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AnimatedMicButton({
    super.key,
    required this.state,
    this.amplitude = 0.0,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 78.0;
    const double containerSize = 160.0;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.state == AssistantState.listening) ...[
              _buildListeningRipples(containerSize),
            ],
            if (widget.state == AssistantState.thinking) ...[
              _buildThinkingAura(buttonSize + 32),
            ],
            if (widget.state == AssistantState.idle) ...[
              _buildIdleGlow(buttonSize + 20),
            ],
            if (widget.state == AssistantState.speaking) ...[
              _buildSpeakingGlow(buttonSize + 24),
            ],
            _buildCoreButton(buttonSize),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningRipples(double size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final progress = _pulseController.value;
        final ampBoost = widget.amplitude * 18.0;

        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final waveProgress = (progress + (index / 3.0)) % 1.0;
            final currentRadius =
                42.0 + (waveProgress * (size / 2 - 42.0)) + ampBoost;
            final opacity = (1.0 - waveProgress).clamp(0.0, 0.7);

            return Container(
              width: currentRadius * 2,
              height: currentRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: VoiceAppColors.recordingRed.withOpacity(opacity * 0.8),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VoiceAppColors.recordingRed.withOpacity(opacity * 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildThinkingAura(double size) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, _) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Colors.transparent,
                  VoiceAppColors.primaryIndigo,
                  VoiceAppColors.primaryCyan,
                  Colors.transparent,
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: VoiceAppColors.primaryCyan.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdleGlow(double size) {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, _) {
        final scale = 1.0 + (_breatheController.value * 0.12);
        final opacity = 0.2 + (_breatheController.value * 0.25);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  VoiceAppColors.primaryIndigo.withOpacity(opacity),
                  VoiceAppColors.primaryPurple.withOpacity(opacity * 0.5),
                  Colors.transparent,
                ],
                stops: const [0.2, 0.6, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeakingGlow(double size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final progress = (math.sin(_pulseController.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: size + (progress * 12),
          height: size + (progress * 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                VoiceAppColors.primaryCyan.withOpacity(0.35 + progress * 0.2),
                VoiceAppColors.primaryPurple.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: VoiceAppColors.primaryCyan.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoreButton(double size) {
    Gradient buttonGradient;
    List<BoxShadow> shadows;
    Widget iconWidget;

    switch (widget.state) {
      case AssistantState.listening:
        buttonGradient = VoiceAppColors.recordingGradient;
        shadows = [
          BoxShadow(
            color: VoiceAppColors.recordingRed.withOpacity(0.6),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ];
        iconWidget = const Icon(
          Icons.stop_rounded,
          color: Colors.white,
          size: 38,
        );
        break;

      case AssistantState.thinking:
        buttonGradient = const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
        );
        shadows = [
          BoxShadow(
            color: VoiceAppColors.primaryIndigo.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
        iconWidget = const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(VoiceAppColors.primaryCyan),
          ),
        );
        break;

      case AssistantState.speaking:
        buttonGradient = VoiceAppColors.purpleCyanGradient;
        shadows = [
          BoxShadow(
            color: VoiceAppColors.primaryCyan.withOpacity(0.5),
            blurRadius: 22,
            spreadRadius: 3,
          ),
        ];
        iconWidget = const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 34,
        );
        break;

      case AssistantState.idle:
      default:
        buttonGradient = VoiceAppColors.indigoPurpleGradient;
        shadows = [
          BoxShadow(
            color: VoiceAppColors.primaryIndigo.withOpacity(0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
        iconWidget = const Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 36,
        );
        break;
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        customBorder: const CircleBorder(),
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: buttonGradient,
            boxShadow: shadows,
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: iconWidget,
            ),
          ),
        ),
      ),
    );
  }
}
