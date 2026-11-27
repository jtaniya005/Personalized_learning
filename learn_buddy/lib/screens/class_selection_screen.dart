import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/page_transitions.dart';
import 'student_details_screen.dart';
import '../services/auth_service.dart';

class ClassSelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ClassSelectionScreen({super.key, this.user});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  int selectedClass = 10;
  bool isSaving = false;

  Future<void> _handleContinue() async {
    setState(() => isSaving = true);

    // Save selected class
    await AuthService.updateDetails(
      studentClass: selectedClass,
    );

    setState(() => isSaving = false);

    if (mounted) {
      // Navigate to Screen 5: Student Details
      final updatedUser = Map<String, dynamic>.from(widget.user ?? {});
      updatedUser['student_class'] = selectedClass;

      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(
          page: StudentDetailsScreen(initialUser: updatedUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // ── Bottom Wavy Gradient Shape ──
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WarmWaveWidget(height: 70),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Back Button & Sparkles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E1B18)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text('✨', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Title: Which Class Are You In?
                  Text(
                    'Which Class Are You In?',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B18),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Choose your current class',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B655B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Option 1: Class 10th Card
                  _buildClassCard(
                    classNum: 10,
                    title: 'Class 10th',
                    subtitle: 'Build a strong foundation for your future',
                    icon: Icons.school_rounded,
                    iconColor: const Color(0xFFEA580C),
                    isSelected: selectedClass == 10,
                  ),
                  const SizedBox(height: 18),

                  // Option 2: Class 12th Card
                  _buildClassCard(
                    classNum: 12,
                    title: 'Class 12th',
                    subtitle: 'Excel in your board exams and explore the best career options',
                    icon: Icons.school_rounded,
                    iconColor: const Color(0xFF262626),
                    isSelected: selectedClass == 12,
                  ),

                  const Spacer(),

                  // Primary Dark Pill Button: Continue ➔
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1B18),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required int classNum,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => selectedClass = classNum),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9EE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE8DECF),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.12) : const Color(0xFF1E1B18).withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Graduation Cap Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFED7AA).withOpacity(0.5) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Class Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B655B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFD1D5DB),
                  width: 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEA580C),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
