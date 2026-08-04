import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The signature element of the app: a card with a spiral-notebook
/// binder edge. It doubles as a structural device — the "holes"
/// are spaced to hint at how many sub-items the card contains,
/// so on a chapter card 3 holes ≈ short chapter, 6 holes ≈ long one.
class NotebookCard extends StatefulWidget {
  final Widget child;
  final Color? background;
  final int holeCount;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool ambientGlow;
  final Color? borderColor;

  const NotebookCard({
    super.key,
    required this.child,
    this.background,
    this.holeCount = 3,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(28, 18, 18, 18),
    this.ambientGlow = false,
    this.borderColor,
  });

  @override
  State<NotebookCard> createState() => _NotebookCardState();
}

class _NotebookCardState extends State<NotebookCard> {
  double scale = 1;

  void _setScale(double s) {
    if (widget.onTap == null) return;
    setState(() => scale = s);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1),
      onTapCancel: () => _setScale(1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.background ?? AppColors.paperCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.borderColor ?? AppColors.rule, width: 1),
            boxShadow: widget.ambientGlow
                ? [
                    BoxShadow(
                      color: AppColors.marigold.withOpacity(0.12),
                      blurRadius: 36,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(padding: widget.padding, child: widget.child),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      widget.holeCount,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.rule, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin dashed rule, used as a section divider echoing notebook paper.
class DashedRule extends StatelessWidget {
  final double height;
  const DashedRule({super.key, this.height = 1});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return Flex(
          direction: Axis.horizontal,
          children: List.generate(
            dashCount,
            (_) => Expanded(
              child: Container(
                height: height,
                margin: const EdgeInsets.only(right: 4),
                color: AppColors.rule,
              ),
            ),
          ),
        );
      },
    );
  }
}
