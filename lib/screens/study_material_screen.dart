import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../models/mock_data.dart';
import '../widgets/animated_scale_press.dart';
import '../widgets/fade_slide_in.dart';

class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  int selectedSubject = 0;

  @override
  Widget build(BuildContext context) {
    final subject = mockSubjects[selectedSubject];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'study_title'), style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          Text(tr(context, 'study_sub'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),

          // Subject selector chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockSubjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final s = mockSubjects[i];
                final selected = i == selectedSubject;
                return AnimatedScalePress(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedSubject = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? s.color : AppColors.paperCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? s.color : AppColors.rule,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          Expanded(
            child: ListView.separated(
              key: ValueKey(selectedSubject),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: subject.chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final c = subject.chapters[i];
                
                final isDone = c.status == ChapterStatus.done;
                final isLocked = c.status == ChapterStatus.locked;
                final isInProgress = c.status == ChapterStatus.inProgress;
                
                Color borderColor = AppColors.rule;
                if (isDone) borderColor = AppColors.teal;
                if (isInProgress) borderColor = AppColors.marigold;
                
                return FadeSlideIn(
                  index: i,
                  child: Opacity(
                    opacity: isLocked ? 0.6 : 1.0,
                    child: NotebookCard(
                    holeCount: 3,
                    borderColor: borderColor,
                    onTap: isLocked ? null : () {},
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.tagColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.tag.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                        color: c.tagColor,
                                      ),
                                    ),
                                  ),
                                  if (isDone) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 16),
                                  ] else if (isLocked) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.lock_rounded, color: AppColors.inkSoft, size: 16),
                                  ]
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(c.title,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 13, color: AppColors.inkSoft),
                                  const SizedBox(width: 4),
                                  Text(c.duration,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.inkSoft),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
