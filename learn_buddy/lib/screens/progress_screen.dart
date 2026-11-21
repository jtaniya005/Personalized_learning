import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/paper_texture.dart';
import '../models/subject_utils.dart';
import '../models/mock_data.dart';
import '../services/auth_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<SubjectInfo> _subjects = [];
  int _streakDays = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getProfile();
    if (profile != null && mounted) {
      final studentClass = profile['student_class'] as int? ?? 10;
      final stream = profile['stream'] as String?;
      final weakSubjects = (profile['weak_subjects'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final streakDays = profile['streak_days'] as int? ?? 0;

      setState(() {
        _subjects = buildSubjectList(
          studentClass: studentClass,
          stream: stream,
          weakSubjects: weakSubjects,
        );
        _streakDays = streakDays;
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
    final weakSubjects = _subjects.where((s) => s.isWeak).toList();
    // TODO: wire to /progress/weekly-activity when built
    final maxMinutes = mockWeekActivity
        .map((d) => d.minutes)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return PaperTexture(
      child: RefreshIndicator(
        color: AppColors.marigold,
        onRefresh: () async {
          await _loadProfile();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
          FadeSlideIn(
            index: 0,
            child: Text(tr(context, 'progress_title'),
                style: Theme.of(context).textTheme.displayLarge),
          ),
          const SizedBox(height: 4),
          Text(tr(context, 'progress_sub'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),

          // ── Stat tiles ──
          FadeSlideIn(
            index: 1,
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '$_streakDays',
                    label: tr(context, 'stat_streak'),
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.marigoldDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // TODO: wire to /progress/summary for real avg score when built
                  child: _StatTile(
                    value: '—',
                    label: tr(context, 'stat_score'),
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.sage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    value: '${weakSubjects.length}',
                    label: tr(context, 'stat_weak'),
                    icon: Icons.flag_rounded,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

        // ── Weekly activity ──
        // TODO: wire to /progress/weekly-activity when built
        Text(tr(context, 'this_week'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        NotebookCard(
          holeCount: 5,
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: mockWeekActivity.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final h = (d.minutes / maxMinutes) * 88 + 12;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${d.minutes}m',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: d.isToday
                                  ? AppColors.marigoldDeep
                                  : AppColors.inkSoft,
                            )),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (i * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) => Container(
                            height: h * val,
                            decoration: BoxDecoration(
                              color: d.isToday
                                  ? AppColors.marigold
                                  : AppColors.sage.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  d.isToday ? FontWeight.w800 : FontWeight.w600,
                              color: d.isToday
                                  ? AppColors.ink
                                  : AppColors.inkSoft,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Subject-wise progress — now from real profile data ──
        Text(tr(context, 'subject_wise'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.marigold),
            ),
          )
        else
          NotebookCard(
            holeCount: 5,
            child: Column(
              children: _subjects.asMap().entries.map((entry) {
                final s = entry.value;
                final isLast = entry.key == _subjects.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(s.icon, size: 16, color: s.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.name,
                                style: Theme.of(context).textTheme.bodyLarge)),
                          if (s.isWeak) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Needs focus',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.coral)),
                            ),
                          ],
                          // TODO: wire to real subject progress when progress module is built
                          Text('${(s.progress * 100).round()}%',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: s.color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: s.progress),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Stack(
                            children: [
                              Container(height: 8, color: AppColors.rule),
                              FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [s.color, AppColors.coral],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 28),

        // ── Weak areas — now based on real weak_subjects from profile ──
        Row(
          children: [
            Text(tr(context, 'practice_first'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${weakSubjects.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.coral)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (weakSubjects.isEmpty)
          NotebookCard(
            holeCount: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No weak subjects flagged — great job! 🎉',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ...weakSubjects.asMap().entries.map((entry) {
            final i = entry.key;
            final w = entry.value;
            return FadeSlideIn(
              index: 4 + i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NotebookCard(
                  holeCount: 3,
                  // TODO: wire onTap to navigate to subject-specific practice when built
                  onTap: () {},
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(w.icon, size: 16, color: w.color),
                                const SizedBox(width: 8),
                                Text(w.name,
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.coral.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Needs focus',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.coral)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tr(context, 'practice_btn'),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
