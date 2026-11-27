import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/app_logo.dart';
import '../models/subject_utils.dart';
import '../services/auth_service.dart';
import 'study_material_screen.dart';
import 'ai_chat_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'voice_assistant_screen.dart';
import 'games/brain_break_menu.dart';
import '../widgets/page_transitions.dart';
import 'student_details_screen.dart';
import '../widgets/voice_assistant_modal.dart';
import '../services/voice_assistant_service.dart';

class HomeScreen extends StatefulWidget {
  final int studentClass;
  final String studentName;
  final int avatarIndex;

  const HomeScreen({
    super.key,
    required this.studentClass,
    this.studentName = 'Rahul',
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
    final pages = [
      _HomeBody(
        studentClass: studentClass,
        studentName: studentName,
        onSelectTab: (idx) => setState(() => navIndex = idx),
        onOpenSettings: _openSettings,
      ),
      const StudyMaterialScreen(),
      const AiChatScreen(),
      const BrainBreakMenu(),
      SettingsScreen(
        studentClass: studentClass,
        studentName: studentName,
        avatarIndex: avatarIndex,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: KeyedSubtree(
                key: ValueKey(navIndex),
                child: pages[navIndex],
              ),
            ),
            // Floating Chatbot Button (active on all tabs except Doubts chat)
            if (navIndex != 2)
              Positioned(
                bottom: 14,
                right: 16,
                child: _buildFloatingChatbot(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomBar(),
    );
  }

  // ── Floating Chatbot Assistant Pill (Floats across screens) ──
  Widget _buildFloatingChatbot() {
    return GestureDetector(
      onTap: () => setState(() => navIndex = 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withOpacity(0.38),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_outlined, size: 18, color: Color(0xFFEA580C)),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ask Buddy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Doubt & Career ✨',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating Dark Bottom Navigation Bar (Screen 8) ──
  Widget _buildFloatingBottomBar() {
    final navItems = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_today_rounded, label: 'Plan'),
      (icon: Icons.chat_bubble_outline_rounded, label: 'Doubts'),
      (icon: Icons.sports_esports_outlined, label: 'Games'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      color: const Color(0xFFFFFDF9),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B18),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(navItems.length, (i) {
            final item = navItems[i];
            final isActive = navIndex == i;
            return GestureDetector(
              onTap: () => setState(() => navIndex = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isActive ? const Color(0xFFEA580C) : const Color(0xFFA8A29E),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? const Color(0xFFEA580C) : const Color(0xFFA8A29E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SCREEN 8: Home Body
// ══════════════════════════════════════════════════════════════
class _HomeBody extends StatefulWidget {
  final int studentClass;
  final String studentName;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenSettings;

  const _HomeBody({
    required this.studentClass,
    required this.studentName,
    required this.onSelectTab,
    required this.onOpenSettings,
  });

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  Map<String, dynamic>? _profile;
  String? _performanceCategory;
  Map<String, dynamic>? _studyPlan;
  List<dynamic> _careerRecs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _profile = profile;
        _performanceCategory = profile['performance_category'] as String?;
        _studyPlan = profile['study_plan'] as Map<String, dynamic>?;
        _careerRecs = (profile['career_recommendations'] as List?) ?? [];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showCareerGuidanceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Career Recommendations',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Grounded with AI & Pinecone based on your subject performance and stream:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6B655B)),
            ),
            const SizedBox(height: 16),
            if (_careerRecs.isNotEmpty)
              ..._careerRecs.take(4).map((car) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8DECF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(car['title'] ?? '', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(car['description'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF524C42))),
                      ],
                    ),
                  ))
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Engineering & Technology (B.Tech / AI / Software)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('• Data Science & Analytics', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('• Design & Product Management', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFocusAreasModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Focus Priority Areas', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Subjects scoring below 60% are flagged by our 6-Tier categorization engine for high-priority revision:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6B655B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Text('Biology (45%) · Weak Tier (<50%)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFFB91C1C))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Recommendation: Fundamental concept review, daily 30-min diagram practice.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF7F1D1D))),
                  const Divider(height: 16, color: Color(0xFFFECACA)),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text('English (58%) · Needs Improve Tier (50-60%)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Recommendation: Weekly 2 comprehension passages and grammar exercises.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF78350F))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Corner Marigold Flower Decoration (Screen 8)
        const Positioned(
          top: 36,
          right: -10,
          child: MarigoldFloralWidget(size: 85),
        ),

        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            // ── Top Bar: Menu, Learn Buddy Logo, Notification Bell ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.menu_rounded, size: 26, color: Color(0xFF1E1B18)),
                  onPressed: widget.onOpenSettings,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Color(0xFFEA580C), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Learn Buddy',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B18),
                      ),
                    ),
                  ],
                ),
                // Notification Bell with Orange Dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.notifications_none_rounded, size: 24, color: Color(0xFF1E1B18)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All caught up! No new notifications.')),
                        );
                      },
                    ),
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFFDF9), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Greeting Header: Hello, Rahul! 👋 ──
            Text(
              'Hello, ${widget.studentName}! 👋',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B18),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Let's make your learning journey\nbetter together.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B655B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // ── Buddy Mascot Banner Card ──
            GestureDetector(
              onTap: () => widget.onSelectTab(2), // Doubts
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9ED),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const BuddyMascotWidget(size: 78),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8DECF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "I'm Buddy!",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1B18),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your study companion 🚀',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── "Your Learning Progress" Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B18),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Learning Progress',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '78%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: const Color(0xFF38332E),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.78,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Quick Action Grid (6 Cards, 3 cols x 2 rows) ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.98,
              children: [
                _buildQuickActionCard(
                  icon: Icons.menu_book_rounded,
                  label: 'My Plan',
                  iconColor: const Color(0xFFEA580C),
                  onTap: () => widget.onSelectTab(1),
                ),
                _buildQuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'My Progress',
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Doubts',
                  iconColor: const Color(0xFFEA580C),
                  onTap: () => widget.onSelectTab(2),
                ),
                _buildQuickActionCard(
                  icon: Icons.explore_outlined,
                  label: 'Career Guide',
                  iconColor: const Color(0xFFEA580C),
                  onTap: _showCareerGuidanceModal,
                ),
                _buildQuickActionCard(
                  icon: Icons.sports_esports_outlined,
                  label: 'Brain Games',
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.of(context).push(BrainBreakMenu.route());
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.track_changes_rounded,
                  label: 'Focus Areas',
                  iconColor: const Color(0xFFD97706),
                  onTap: _showFocusAreasModal,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8DECF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF26231F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
