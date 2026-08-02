import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notebook_card.dart';
import '../../widgets/game_results_overlay.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/shake_widget.dart';

class MathSprintGame extends StatefulWidget {
  final VoidCallback onBackToGames;

  const MathSprintGame({super.key, required this.onBackToGames});

  @override
  State<MathSprintGame> createState() => _MathSprintGameState();
}

class _MathSprintGameState extends State<MathSprintGame> with SingleTickerProviderStateMixin {
  late final AnimationController _timerController;
  final Random _random = Random();

  int _score = 0;
  bool _isGameOver = false;

  late String _question;
  late int _correctAnswer;
  late List<int> _options;
  int? _selectedAnswer;
  bool? _wasCorrect;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
    
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward().whenComplete(() {
        if (mounted) {
          setState(() {
            _isGameOver = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    // Generate a random arithmetic question
    final op = _random.nextInt(3); // 0: +, 1: -, 2: *
    int a, b;
    String symbol;
    if (op == 0) {
      a = _random.nextInt(40) + 10;
      b = _random.nextInt(40) + 10;
      symbol = '+';
      _correctAnswer = a + b;
    } else if (op == 1) {
      a = _random.nextInt(50) + 20;
      b = _random.nextInt(20) + 1;
      symbol = '-';
      _correctAnswer = a - b;
    } else {
      a = _random.nextInt(12) + 2;
      b = _random.nextInt(10) + 2;
      symbol = '×';
      _correctAnswer = a * b;
    }
    
    _question = '$a $symbol $b';
    _options = [_correctAnswer];

    // Generate 3 unique wrong answers
    while (_options.length < 4) {
      final variance = _random.nextInt(10) - 5;
      final wrongAnswer = _correctAnswer + (variance == 0 ? 1 : variance);
      if (!_options.contains(wrongAnswer) && wrongAnswer > 0) {
        _options.add(wrongAnswer);
      }
    }
    _options.shuffle(_random);
  }

  void _handleAnswer(int selected) async {
    if (_selectedAnswer != null || _isGameOver) return; // Prevent multiple taps

    setState(() {
      _selectedAnswer = selected;
      _wasCorrect = selected == _correctAnswer;
      if (_wasCorrect!) {
        _score++;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.vibrate();
      }
    });

    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted && !_isGameOver) {
      setState(() {
        _selectedAnswer = null;
        _wasCorrect = null;
        _generateQuestion();
      });
    }
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _isGameOver = false;
      _selectedAnswer = null;
      _wasCorrect = null;
      _generateQuestion();
    });
    _timerController.reset();
    _timerController.forward().whenComplete(() {
      if (mounted) {
        setState(() {
          _isGameOver = true;
        });
      }
    });
  }

  String _getResultMessage() {
    if (_score > 20) return "Incredible speed! You're a human calculator! 🧠⚡";
    if (_score > 10) return "Great job! Keep the brain gears turning. ⚙️💡";
    return "Nice warmup! A quick break makes you study better. 🌱";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: widget.onBackToGames,
        ),
        title: const Text('Quick Math Sprint'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar: Score and Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.paperCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.rule),
                      ),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_score),
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, val, child) {
                          return Transform.scale(
                            scale: val,
                            child: child,
                          );
                        },
                        child: Text(
                          'Score: $_score',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.grape,
                          ),
                        ),
                      ),
                    ),
                    _AnimatedTimer(controller: _timerController),
                  ],
                ),
                const Spacer(flex: 1),
                
                // Question
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _question,
                      key: ValueKey(_question),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 64,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),

                // Options Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    Color bgColor = AppColors.paperCard;
                    Color textColor = AppColors.ink;
                    bool shouldShake = false;
                    bool isRight = option == _correctAnswer;

                    if (_selectedAnswer != null) {
                      if (isRight) {
                        bgColor = AppColors.sage.withOpacity(0.2);
                        textColor = AppColors.sage;
                      } else if (option == _selectedAnswer) {
                        bgColor = AppColors.coral.withOpacity(0.2);
                        textColor = AppColors.coral;
                        shouldShake = true;
                      }
                    }

                    return ShakeWidget(
                      shouldShake: shouldShake,
                      child: BouncingButton(
                        onTap: _selectedAnswer == null ? () => _handleAnswer(option) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: bgColor == AppColors.paperCard ? AppColors.rule : textColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.toString(),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: textColor,
                                ),
                              ),
                              if (_selectedAnswer != null && isRight)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.elasticOut,
                                    builder: (context, val, child) => Transform.scale(
                                      scale: val,
                                      child: const Icon(Icons.check_circle_rounded, color: AppColors.sage),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          
          if (_isGameOver)
            GameResultsOverlay(
              score: _score,
              title: "Time's up!",
              message: "You solved $_score questions!\n${_getResultMessage()}",
              onPlayAgain: _restartGame,
              onBackToGames: widget.onBackToGames,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedTimer extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedTimer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final remaining = (1.0 - controller.value) * 30;
        final isLow = remaining <= 5.0;
        final pulseScale = isLow ? 1.0 + 0.05 * sin(remaining * pi * 2).abs() : 1.0;
        return Transform.scale(
          scale: pulseScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: 1.0 - controller.value,
                  strokeWidth: 4,
                  backgroundColor: AppColors.rule,
                  color: isLow ? AppColors.coral : AppColors.marigoldDeep,
                ),
              ),
              Text(
                remaining.ceil().toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isLow ? AppColors.coral : AppColors.ink,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
