import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../models/subject_utils.dart';
import '../services/auth_service.dart';
import '../widgets/animated_scale_press.dart';
import '../widgets/fade_slide_in.dart';

class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  int selectedSubject = 0;
  List<SubjectInfo> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final profile = await AuthService.getProfile();
    if (profile != null && mounted) {
      final studentClass = profile['student_class'] as int? ?? 10;
      final stream = profile['stream'] as String?;
      final weakSubjects = (profile['weak_subjects'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _subjects = buildSubjectList(
          studentClass: studentClass,
          stream: stream,
          weakSubjects: weakSubjects,
        );
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _subjects = buildSubjectList(
          studentClass: 10,
          stream: null,
          weakSubjects: [],
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.marigold),
      );
    }

    if (_subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects found for your class/stream.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final subject = _subjects[selectedSubject];

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

          // Subject selector chips — now from real data
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final s = _subjects[i];
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected ? Colors.white : AppColors.inkSoft,
                            ),
                          ),
                          if (s.isWeak) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.flag_rounded,
                              size: 12,
                              color: selected ? Colors.white.withOpacity(0.8) : AppColors.coral,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          // TODO: wire to /subjects/{id}/chapters when built
          // For now, show a placeholder message since chapters data
          // requires the chapters API which is not yet implemented.
          Expanded(
            child: Center(
              child: FadeSlideIn(
                index: 0,
                child: NotebookCard(
                  holeCount: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(subject.icon, size: 40, color: subject.color.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          subject.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chapters and study material\ncoming soon!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
