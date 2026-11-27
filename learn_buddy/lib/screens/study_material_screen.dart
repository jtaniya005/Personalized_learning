import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_decorations.dart';
import '../models/subject_utils.dart';
import '../services/auth_service.dart';

class StudyMaterialScreen extends StatefulWidget {
  const StudyMaterialScreen({super.key});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  int selectedPeriod = 0; // 0: This Week, 1: This Month, 2: Overall
  Map<String, dynamic>? _studyPlan;
  List<dynamic> _careerRecs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final profile = await AuthService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _studyPlan = profile['study_plan'] as Map<String, dynamic>?;
        _careerRecs = (profile['career_recommendations'] as List?) ?? [];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showCareerDetails() {
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
                  'Career Pathways',
                  style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Grounded via Pinecone vector index on career streams & curriculum data:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6B655B)),
            ),
            const SizedBox(height: 16),
            if (_careerRecs.isNotEmpty)
              ..._careerRecs.map((car) => Container(
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
            else ...[
              Container(
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
                    Text('Engineering & Technology', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Focus on Mathematics & Physics. Best pathways: B.Tech in CSE, AI, Robotics or Mechanical Engineering.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF524C42))),
                  ],
                ),
              ),
              Container(
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
                    Text('Data Science & Quantitative Finance', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Leverage high mathematical aptitude. Pathways: Statistics, Data Engineering, Actuarial Science.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF524C42))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Subject tasks for Screen 10
    final List<Map<String, dynamic>> tasks = [
      {
        'subject': 'Mathematics',
        'subtitle': 'Practice 20 questions\n(Topic: Trigonometry)',
        'hours': '2h',
        'icon': Icons.menu_book_rounded,
        'iconColor': const Color(0xFFEA580C),
        'iconBg': const Color(0xFFFFF3E5),
      },
      {
        'subject': 'Physics',
        'subtitle': 'Revise Electric Charges',
        'hours': '1.5h',
        'icon': Icons.science_outlined,
        'iconColor': const Color(0xFF10B981),
        'iconBg': const Color(0xFFECFDF5),
      },
      {
        'subject': 'Chemistry',
        'subtitle': 'Complete Notes\n(Organic Chemistry)',
        'hours': '2h',
        'icon': Icons.biotech_outlined,
        'iconColor': const Color(0xFF059669),
        'iconBg': const Color(0xFFECFDF5),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // Corner Marigold Flower Decoration on bottom right (Screen 10)
          const Positioned(
            bottom: -15,
            right: -15,
            child: MarigoldFloralWidget(size: 110),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E1B18)),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const Text('✨', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                ),

                // ── Title Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Study Plan',
                        style: GoogleFonts.fraunces(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B18),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'A personalized plan for your success',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B655B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Segmented Control / Pill Tabs (Screen 10) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      _buildPillTab('This Week', 0),
                      const SizedBox(width: 10),
                      _buildPillTab('This Month', 1),
                      const SizedBox(width: 10),
                      _buildPillTab('Overall', 2),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Subject Task Cards List ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    children: [
                      ...tasks.map((t) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8DECF)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon with background
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: t['iconBg'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(t['icon'] as IconData, color: t['iconColor'] as Color, size: 24),
                              ),
                              const SizedBox(width: 14),

                              // Title & Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['subject'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1B18),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t['subtitle'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF6B655B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Hours & Play arrow
                              Row(
                                children: [
                                  Text(
                                    t['hours'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E1B18),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF78716C)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // ── Career Suggestion Lightbulb Card (Screen 10) ──
                      GestureDetector(
                        onTap: _showCareerDetails,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Lightbulb Icon in Circle
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xFFEA580C),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Body
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Career Suggestion',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E1B18),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You can explore Engineering, Data Science and more!',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF6B655B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF78716C)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String title, int index) {
    final isSelected = selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE8DECF),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF524C42),
          ),
        ),
      ),
    );
  }
}
