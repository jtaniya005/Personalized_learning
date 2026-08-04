import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notebook_card.dart';
import '../../widgets/fade_slide_in.dart';
import 'math_sprint_game.dart';
import 'memory_match_game.dart';
import 'tic_tac_toe_game.dart';

class BrainBreakMenu extends StatefulWidget {
  const BrainBreakMenu({super.key});

  static Route route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const BrainBreakMenu(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  State<BrainBreakMenu> createState() => _BrainBreakMenuState();
}

class _BrainBreakMenuState extends State<BrainBreakMenu> {
  int? _activeGameIndex;

  void _onBackToGames() {
    setState(() {
      _activeGameIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeGameIndex == 0) {
      return MathSprintGame(onBackToGames: _onBackToGames);
    } else if (_activeGameIndex == 1) {
      return MemoryMatchGame(onBackToGames: _onBackToGames);
    } else if (_activeGameIndex == 2) {
      return TicTacToeGame(onBackToGames: _onBackToGames);
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Brain Break'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
          children: [
            FadeSlideIn(
              index: 0,
              child: Text(
                'Time for a quick break! 🎮',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              index: 1,
              child: Text(
                'Pick a mini-game to refresh your mind before jumping back into your studies.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            
            FadeSlideIn(
              index: 2,
              child: NotebookCard(
                onTap: () => setState(() => _activeGameIndex = 0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.marigold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calculate_rounded, color: AppColors.marigoldDeep),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Math Sprint', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('30 seconds. How many can you solve?', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            FadeSlideIn(
              index: 3,
              child: NotebookCard(
                onTap: () => setState(() => _activeGameIndex = 1),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.sage.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.view_module_rounded, color: AppColors.sage),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Memory Match', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Match the subjects to test your memory.', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            FadeSlideIn(
              index: 4,
              child: NotebookCard(
                onTap: () => setState(() => _activeGameIndex = 2),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.skyInk.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.grid_3x3_rounded, color: AppColors.skyInk),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tic-Tac-Toe vs Buddy', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('A classic game against your study buddy.', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}
