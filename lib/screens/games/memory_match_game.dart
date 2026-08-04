import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_results_overlay.dart';
import '../../widgets/bouncing_button.dart';

class MemoryMatchGame extends StatefulWidget {
  final VoidCallback onBackToGames;

  const MemoryMatchGame({super.key, required this.onBackToGames});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  // Existing icons from the app
  final List<IconData> _iconPool = [
    Icons.functions_rounded, // Math
    Icons.science_rounded, // Science
    Icons.public_rounded, // Social Science
    Icons.menu_book_rounded, // English
    Icons.computer_rounded, // Computer
    Icons.psychology_rounded, // Logic
    Icons.history_edu_rounded, // History
    Icons.auto_awesome_rounded, // Magic/Awesome
  ];

  late List<IconData> _cards;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;

  int? _firstFlippedIndex;
  bool _isProcessing = false;
  
  int _moves = 0;
  late DateTime _startTime;
  int _timeTakenSeconds = 0;
  Timer? _gameTimer;

  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _cards = [];
    _cards.addAll(_iconPool);
    _cards.addAll(_iconPool);
    _cards.shuffle(Random());
    
    _isFlipped = List.generate(16, (i) => false);
    _isMatched = List.generate(16, (i) => false);
    
    _moves = 0;
    _firstFlippedIndex = null;
    _isProcessing = false;
    _isGameOver = false;
    _timeTakenSeconds = 0;
    _startTime = DateTime.now();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameOver) {
        setState(() {
          _timeTakenSeconds = DateTime.now().difference(_startTime).inSeconds;
        });
      }
    });
  }

  void _onCardTap(int index) async {
    if (_isProcessing || _isFlipped[index] || _isMatched[index] || _isGameOver) {
      return;
    }

    setState(() {
      _isFlipped[index] = true;
    });

    if (_firstFlippedIndex == null) {
      // First card flipped
      _firstFlippedIndex = index;
    } else {
      // Second card flipped
      _moves++;
      _isProcessing = true;
      final firstIndex = _firstFlippedIndex!;

      if (_cards[firstIndex] == _cards[index]) {
        // Match!
        setState(() {
          _isMatched[firstIndex] = true;
          _isMatched[index] = true;
        });
        _checkWinCondition();
        _isProcessing = false;
        _firstFlippedIndex = null;
      } else {
        // No match
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          setState(() {
            _isFlipped[firstIndex] = false;
            _isFlipped[index] = false;
          });
          _isProcessing = false;
          _firstFlippedIndex = null;
        }
      }
    }
  }

  void _checkWinCondition() {
    if (!_isMatched.contains(false)) {
      _gameTimer?.cancel();
      setState(() {
        _isGameOver = true;
      });
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
        title: const Text('Memory Match'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
              children: [
                // Stats Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Moves: $_moves',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      'Time: ${_formatTime(_timeTakenSeconds)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, val, child) {
                          return Transform.scale(
                            scale: val,
                            child: child,
                          );
                        },
                        child: _MemoryCard(
                          icon: _cards[index],
                          isFlipped: _isFlipped[index],
                          isMatched: _isMatched[index],
                          onTap: () => _onCardTap(index),
                        ),
                      );
                    },
                  ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isGameOver)
            GameResultsOverlay(
              score: _moves,
              title: "You won!",
              message: "You matched all pairs in ${_formatTime(_timeTakenSeconds)} with $_moves moves.",
              onPlayAgain: () {
                setState(() {
                  _startNewGame();
                });
              },
              onBackToGames: widget.onBackToGames,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final IconData icon;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.icon,
    required this.isFlipped,
    required this.isMatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      scaleFactor: 0.9,
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, val, child) {
          final isUnder = val > (pi / 2);
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(val),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _CardFace(icon: icon, isMatched: isMatched),
                  )
                : const _CardBack(),
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.marigold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.marigoldDeep.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.help_outline_rounded,
        color: AppColors.marigoldDeep,
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final IconData icon;
  final bool isMatched;

  const _CardFace({required this.icon, required this.isMatched});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(isMatched),
      tween: Tween(begin: isMatched ? 0.8 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isMatched ? AppColors.sage.withOpacity(0.15) : AppColors.paperCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMatched ? AppColors.sage : AppColors.rule,
                width: isMatched ? 2.5 : 1,
              ),
              boxShadow: isMatched
                  ? [BoxShadow(color: AppColors.sage.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                  : [],
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 32,
              color: isMatched ? AppColors.sage : AppColors.ink,
            ),
          ),
        );
      },
    );
  }
}
