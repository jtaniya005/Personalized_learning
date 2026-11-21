import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/confetti_overlay.dart';

class GameResultsOverlay extends StatelessWidget {
  final int score;
  final String title;
  final String message;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToGames;

  const GameResultsOverlay({
    super.key,
    required this.score,
    required this.title,
    required this.message,
    required this.onPlayAgain,
    required this.onBackToGames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper.withOpacity(0.9),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - 0.8) / 0.2).clamp(0.0, 1.0), // Fade in alongside scale, clamp to avoid assertion
              child: child,
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            NotebookCard(
          background: AppColors.paperCard,
          holeCount: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.marigoldDeep,
                      )),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              BouncingButton(
                onTap: onPlayAgain,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.marigoldDeep,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Play Again'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BouncingButton(
                onTap: onBackToGames,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBackToGames,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paper,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      side: BorderSide(color: AppColors.rule),
                    ),
                    child: const Text('Back to games'),
                  ),
                ),
              ),
            ],
          ),
        ),
        ConfettiOverlay(isPlaying: score > 0 || title.contains("won") || title.contains("Incredible")),
      ],
    ),
      ),
    );
  }
}
