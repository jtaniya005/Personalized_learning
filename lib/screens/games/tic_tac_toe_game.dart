import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_results_overlay.dart';
import '../../widgets/bouncing_button.dart';

class TicTacToeGame extends StatefulWidget {
  final VoidCallback onBackToGames;

  const TicTacToeGame({super.key, required this.onBackToGames});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  // 0: empty, 1: player (X), 2: AI (Buddy)
  late List<int> _board;
  bool _playerTurn = true;
  bool _isGameOver = false;
  String _resultTitle = '';
  String _resultMessage = '';
  
  List<int>? _winningLine; // Indices of winning cells

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _board = List.filled(9, 0);
      _playerTurn = true;
      _isGameOver = false;
      _resultTitle = '';
      _resultMessage = '';
      _winningLine = null;
    });
  }

  void _onCellTap(int index) async {
    if (_isGameOver || !_playerTurn || _board[index] != 0) return;

    setState(() {
      _board[index] = 1;
      _playerTurn = false;
    });

    if (_checkWin(1)) {
      await Future.delayed(const Duration(milliseconds: 600));
      _endGame("You won! 🎉", "Great moves! You outsmarted me this time.");
      return;
    }
    if (_checkDraw()) {
      await Future.delayed(const Duration(milliseconds: 600));
      _endGame("It's a draw! 🤝", "Wow, we're evenly matched! Another round?");
      return;
    }

    // AI Move
    await Future.delayed(const Duration(milliseconds: 800)); // Felt slightly longer for "thinking"
    if (mounted && !_isGameOver) {
      _makeAiMove();
    }
  }

  void _makeAiMove() {
    // 1. Try to win
    int bestMove = _findWinningMove(2);
    
    // 2. Block player from winning
    if (bestMove == -1) {
      bestMove = _findWinningMove(1);
    }
    
    // 3. Pick center if available
    if (bestMove == -1 && _board[4] == 0) {
      bestMove = 4;
    }

    // 4. Random available cell
    if (bestMove == -1) {
      final available = [];
      for (int i = 0; i < 9; i++) {
        if (_board[i] == 0) available.add(i);
      }
      if (available.isNotEmpty) {
        bestMove = available[Random().nextInt(available.length)];
      }
    }

    if (bestMove != -1) {
      setState(() {
        _board[bestMove] = 2;
        _playerTurn = true;
      });

      if (_checkWin(2)) {
        Future.delayed(const Duration(milliseconds: 600)).then((_) {
          if (mounted) _endGame("I won! 🤖", "Good game! But don't worry, I practice a lot. Rematch?");
        });
        return;
      }
      if (_checkDraw()) {
        Future.delayed(const Duration(milliseconds: 600)).then((_) {
          if (mounted) _endGame("It's a draw! 🤝", "Wow, we're evenly matched! Another round?");
        });
        return;
      }
    }
  }

  int _findWinningMove(int player) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6]             // diagonals
    ];

    for (final line in lines) {
      int count = 0;
      int emptyIdx = -1;
      for (final idx in line) {
        if (_board[idx] == player) count++;
        else if (_board[idx] == 0) emptyIdx = idx;
      }
      if (count == 2 && emptyIdx != -1) {
        return emptyIdx;
      }
    }
    return -1;
  }

  bool _checkWin(int player) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (final line in lines) {
      if (_board[line[0]] == player &&
          _board[line[1]] == player &&
          _board[line[2]] == player) {
        setState(() {
          _winningLine = line;
        });
        return true;
      }
    }
    return false;
  }

  bool _checkDraw() {
    return !_board.contains(0);
  }

  void _endGame(String title, String message) {
    setState(() {
      _isGameOver = true;
      _resultTitle = title;
      _resultMessage = message;
    });
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
        title: const Text('Tic-Tac-Toe vs Buddy'),
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
                const SizedBox(height: 16),
                // Turn indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.paperCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.rule),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _playerTurn ? "Your turn" : "Buddy is thinking...",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                      if (!_playerTurn) ...[
                        const SizedBox(width: 12),
                        const _ThinkingDots(),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Board
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return BouncingButton(
                            scaleFactor: 0.9,
                            onTap: () => _onCellTap(index),
                            child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: AppColors.paperCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _board[index] == 0
                                  ? AppColors.rule
                                  : (_board[index] == 1 ? AppColors.marigoldDeep : AppColors.grape),
                              width: _board[index] == 0 ? 1 : 2,
                            ),
                          ),
                          alignment: Alignment.center,
                                  child: _board[index] == 0
                                  ? null
                                  : TweenAnimationBuilder<double>(
                                      key: ValueKey(_board[index]),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.elasticOut,
                                      builder: (context, val, child) => Transform.scale(
                                        scale: val,
                                        child: Opacity(
                                          opacity: val.clamp(0.0, 1.0),
                                          child: child,
                                        ),
                                      ),
                                      child: _board[index] == 1
                                          ? const Icon(Icons.close_rounded, size: 64, color: AppColors.marigoldDeep)
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [AppColors.marigold, AppColors.coral],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: const Text('🙂', style: TextStyle(fontSize: 24)),
                                            ),
                                    ),
                            ),
                          );
                        },
                      ),
                      if (_winningLine != null)
                        _WinningLineOverlay(winningLine: _winningLine!),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isGameOver)
            GameResultsOverlay(
              score: 0,
              title: _resultTitle,
              message: _resultMessage,
              onPlayAgain: _startNewGame,
              onBackToGames: widget.onBackToGames,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
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
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            double progress = (_controller.value - delay).clamp(0.0, 1.0);
            if (progress > 0.5) {
              progress = 1.0 - progress; // ping pong
            }
            final offset = -progress * 8; // bounce up
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.inkSoft,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _WinningLineOverlay extends StatelessWidget {
  final List<int> winningLine;

  const _WinningLineOverlay({required this.winningLine});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _LinePainter(winningLine, val),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<int> line;
  final double progress;

  _LinePainter(this.line, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final cellW = size.width / 3;
    final cellH = size.height / 3;

    // Helper to get center of a cell
    Offset getCenter(int index) {
      final r = index ~/ 3;
      final c = index % 3;
      return Offset(c * cellW + cellW / 2, r * cellH + cellH / 2);
    }

    final p1 = getCenter(line.first);
    final p2 = getCenter(line.last);

    // Calculate actual end point based on progress
    final currentP2 = Offset(
      p1.dx + (p2.dx - p1.dx) * progress,
      p1.dy + (p2.dy - p1.dy) * progress,
    );

    final paint = Paint()
      ..color = AppColors.sage.withOpacity(0.8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1, currentP2, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.line != line;
  }
}
