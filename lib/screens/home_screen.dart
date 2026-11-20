import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/paper_texture.dart';
import '../models/subject_utils.dart';
import '../models/mock_data.dart';
import '../services/auth_service.dart';
import 'study_material_screen.dart';
import 'ai_chat_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'voice_assistant_screen.dart';
import 'games/brain_break_menu.dart';
import '../widgets/page_transitions.dart';

class HomeScreen extends StatefulWidget {
  final int studentClass;
  final String studentName;
  final int avatarIndex;

  const HomeScreen({
    super.key,
    required this.studentClass,
    this.studentName = 'Student',
    this.avatarIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int navIndex = 0;
  late int studentClass = widget.studentClass;
  late String studentName = widget.studentName;
  late int avatarIndex = widget.avatarIndex;

  void _openSettings() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      FadeSlidePageRoute(
        page: SettingsScreen(
          studentClass: studentClass,
          studentName: studentName,
          avatarIndex: avatarIndex,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        studentName = result['name'] as String;
        avatarIndex = result['avatarIndex'] as int;
        studentClass = result['studentClass'] as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (icon: Icons.home_rounded, label: tr(context, 'nav_home')),
      (icon: Icons.menu_book_rounded, label: tr(context, 'nav_study')),
      (icon: Icons.chat_bubble_rounded, label: tr(context, 'nav_buddy')),
      (icon: Icons.insights_rounded, label: tr(context, 'nav_progress')),
    ];

    final pages = [
      _HomeBody(
        studentClass: studentClass,
        studentName: studentName,
        avatarIndex: avatarIndex,
        onOpenChat: () => setState(() => navIndex = 2),
        onOpenSettings: _openSettings,
      ),
      const StudyMaterialScreen(),
      const AiChatScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: KeyedSubtree(key: ValueKey(navIndex), child: pages[navIndex]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.rule)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / navItems.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * navIndex + itemWidth * 0.12,
                  top: 0,
                  child: Container(
                    width: itemWidth * 0.76,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.marigold.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navItems.length, (i) {
                    final item = navItems[i];
                    return _NavItem(
                      icon: item.icon,
                      label: item.label,
                      active: navIndex == i,
                      onTap: () => setState(() => navIndex = i),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _greetingKey() {
  final hour = DateTime.now().hour;
  if (hour < 5) return 'greet_late';
  if (hour < 12) return 'greet_morning';
  if (hour < 17) return 'greet_afternoon';
  if (hour < 20) return 'greet_evening';
  return 'greet_night';
}

const List<String> _quotes = [
  "Small steps every day beat cramming every time. 🌱",
  "You don't have to be perfect, just consistent. ✨",
  "Future you is already proud of today's effort. 💪",
  "Progress, not perfection — one chapter at a time. 📖",
];

class _HomeBody extends StatefulWidget {
  final int studentClass;
  final String studentName;
  final int avatarIndex;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenSettings;

  const _HomeBody({
    required this.studentClass,
    required this.studentName,
    required this.avatarIndex,
    required this.onOpenChat,
    required this.onOpenSettings,
  });

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
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
      final studentClass = profile['student_class'] as int? ?? widget.studentClass;
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
      // Offline fallback — derive from widget params with no weak subjects
      setState(() {
        _subjects = buildSubjectList(
          studentClass: widget.studentClass,
          stream: null,
          weakSubjects: [],
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = avatarOptions[widget.avatarIndex % avatarOptions.length];
    final quote = _quotes[DateTime.now().day % _quotes.length];

    return PaperTexture(
      child: RefreshIndicator(
        color: AppColors.marigold,
        onRefresh: () async {
          await _loadProfile();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            // ── Top bar: voice assistant & settings ──
            FadeSlideIn(
              index: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VoiceAssistantScreen.withNewController(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Voice AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onOpenSettings,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.paperCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.rule),
                      ),
                      child: Icon(Icons.settings_outlined,
                          size: 18, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),

          // ── Greeting with avatar ──
          FadeSlideIn(
            index: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: avatar.gradient),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatar.gradient.first.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(avatar.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${tr(context, _greetingKey())}, ${widget.studentName}! 👋',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 2),
                      Text('${tr(context, 'class_label')} ${widget.studentClass} · ${tr(context, 'board_exam_mode')}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                _StreakBadge(days: _streakDays),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Quote of the day ──
          FadeSlideIn(
            index: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                quote,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ── Buddy nudge ──
          // TODO: wire to /chat/daily-checkin when built
          FadeSlideIn(
            index: 3,
            child: NotebookCard(
              background: AppColors.ink,
              holeCount: 4,
              onTap: widget.onOpenChat,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.marigold, AppColors.coral],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.face_retouching_natural_rounded, color: AppColors.paper, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(context, 'nudge_title'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.paper)),
                        const SizedBox(height: 2),
                        Text(tr(context, 'nudge_sub'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: AppColors.paper.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.paper),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Brain Break ──
          FadeSlideIn(
            index: 4,
            child: NotebookCard(
              holeCount: 3,
              onTap: () {
                Navigator.of(context).push(BrainBreakMenu.route());
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.marigold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.videogame_asset_rounded, color: AppColors.marigoldDeep, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Brain Break',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 2),
                        Text('Take a quick mini-game breather',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  Icon(Icons.videogame_asset_rounded, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          FadeSlideIn(
            index: 5,
            child: Row(
              children: [
                Text(tr(context, 'todays_plan'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                // TODO: wire to /progress/summary when built
                const _DailyProgressRing(progress: 0.0),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Subject grid — real data from profile ──
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.marigold),
              ),
            )
          else if (_subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No subjects found for your class/stream.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, i) {
                final s = _subjects[i];
                return FadeSlideIn(
                  index: 6 + i,
                  child: _SubjectCard(subject: s),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyProgressRing extends StatelessWidget {
  final double progress;
  const _DailyProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(
          painter: _RingPainter(value: value, color: AppColors.marigoldDeep, trackWidth: 2.5),
        ),
      ),
    );
  }
}

/// Streak badge with a gentle pulse to draw the eye without being loud.
class _StreakBadge extends StatefulWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  State<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<_StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.marigold.withOpacity(0.22),
              AppColors.coral.withOpacity(0.16),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final pulse = controller.value;
                return Transform.scale(
                  scale: 0.85 + 0.15 * pulse,
                  child: Opacity(
                    opacity: 0.6 + 0.4 * pulse,
                    child: child,
                  ),
                );
              },
              child: const Icon(Icons.local_fire_department_rounded,
                  size: 18, color: AppColors.marigoldDeep),
            ),
            const SizedBox(width: 4),
            Text('${widget.days}',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.ink)),
          ],
      ),
    );
  }
}

/// A subject card with its own color identity: tinted background, a
/// colored shadow, and a small animated progress ring in the corner.
/// Shows a "Needs focus" badge for weak subjects.
class _SubjectCard extends StatelessWidget {
  final SubjectInfo subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            subject.color.withOpacity(0.07), AppColors.paperCard),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: subject.color.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: subject.color.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      subject.color.withOpacity(0.9),
                      subject.color.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: subject.color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(subject.icon, color: Colors.white, size: 19),
              ),
              const Spacer(),
              _ProgressRing(progress: subject.progress, color: subject.color),
            ],
          ),
          const SizedBox(height: 10),

          // ── Weak subject badge or generic subtitle (replaces the old empty Spacer gap) ──
          if (subject.isWeak)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, size: 11, color: AppColors.coral),
                  const SizedBox(width: 4),
                  Text(
                    'Needs focus',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Ready to start',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ),

          const Spacer(),

          Text(subject.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: subject.progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                children: [
                  Container(height: 6, color: AppColors.rule),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [subject.color, AppColors.coral],
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
  }
}

/// Small animated percentage ring — sits top-right of each subject
/// card, giving a second, more glanceable read on progress.
class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  const _ProgressRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(34, 34),
              painter: _RingPainter(value: value, color: color),
            ),
            Text(
              '${(value * 100).round()}',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double trackWidth;
  _RingPainter({required this.value, required this.color, this.trackWidth = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (trackWidth / 2);
    final track = Paint()
      ..color = AppColors.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.marigoldDeep : AppColors.inkSoft;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
