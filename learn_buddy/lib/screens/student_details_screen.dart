import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/page_transitions.dart';
import '../models/subject_utils.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUser;

  const StudentDetailsScreen({super.key, this.initialUser});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

enum OnboardingStep { details, marksheetUpload, marksheetReview, planReveal }

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  OnboardingStep currentStep = OnboardingStep.details;

  // Step 1: Details (Screen 5)
  final nameController = TextEditingController(text: 'Rahul Sharma');
  final schoolController = TextEditingController(text: 'Delhi Public School');
  int selectedClass = 10;
  String selectedBoard = 'CBSE';
  String selectedStream = 'Science';
  List<String> selectedSubjects = ['Maths', 'Physics', 'Chemistry', 'English', 'Biology'];

  final List<String> availableBoards = [
    'CBSE',
    'ICSE / ISC',
    'State Board (UP / Bihar / MP)',
    'Maharashtra State Board',
    'Other'
  ];

  final List<String> streamOptions = [
    'Science',
    'Commerce',
    'Arts / Humanities'
  ];

  // Step 2 & 3: Marksheet (Screen 6 & Review)
  bool isUploading = false;
  String? uploadedFileName;
  String? ocrError;
  List<String> ocrWarnings = [];
  final percentageController = TextEditingController(text: '86.5');
  List<Map<String, TextEditingController>> marksControllers = [];

  // Step 4: Results (Screen 7)
  Map<String, dynamic>? analysisResult;

  @override
  void initState() {
    super.initState();
    _populateInitialData();
  }

  void _populateInitialData() {
    final user = widget.initialUser ?? AuthService.currentUser;
    if (user != null) {
      if (user['name'] != null && (user['name'] as String).isNotEmpty) {
        nameController.text = user['name'];
      }
      if (user['school'] != null && (user['school'] as String).isNotEmpty) {
        schoolController.text = user['school'];
      }
      selectedClass = user['student_class'] as int? ?? 10;
      selectedBoard = user['board'] ?? 'CBSE';
      if (user['stream'] != null) {
        selectedStream = user['stream'];
      }
    }
    _syncDefaultSubjects();
  }

  void _syncDefaultSubjects() {
    // Default subject list
    if (selectedClass == 10) {
      selectedSubjects = ['Maths', 'Science', 'English', 'Social Science', 'Hindi'];
    } else {
      if (selectedStream == 'Commerce') {
        selectedSubjects = ['Accountancy', 'Economics', 'Business Studies', 'English', 'Maths'];
      } else if (selectedStream == 'Arts / Humanities') {
        selectedSubjects = ['History', 'Political Science', 'Geography', 'English', 'Economics'];
      } else {
        selectedSubjects = ['Maths', 'Physics', 'Chemistry', 'English', 'Biology'];
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    schoolController.dispose();
    percentageController.dispose();
    for (final m in marksControllers) {
      m['subject']?.dispose();
      m['obtained']?.dispose();
      m['total']?.dispose();
    }
    super.dispose();
  }

  // ── File Picking ──
  Future<void> _pickFile(bool isPdf) async {
    setState(() {
      isUploading = true;
      ocrError = null;
      ocrWarnings = [];
    });

    try {
      Uint8List? fileBytes;
      String? fileName;

      if (isPdf) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
        if (result != null && result.files.single.bytes != null) {
          fileBytes = result.files.single.bytes;
          fileName = result.files.single.name;
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          fileBytes = await picked.readAsBytes();
          fileName = picked.name;
        }
      }

      if (fileBytes == null || fileName == null) {
        setState(() => isUploading = false);
        return;
      }

      uploadedFileName = fileName;

      // Call Backend Marksheet Extract & 10th/12th Validation
      final extractRes = await AuthService.extractMarksheet(fileBytes, fileName);

      if (extractRes['success'] == true) {
        final data = extractRes['data'];
        final marksList = data['marks'] as List? ?? [];

        if (data['warnings'] != null) {
          ocrWarnings = List<String>.from(data['warnings']);
        }

        if (data['previous_class_percentage'] != null) {
          percentageController.text = data['previous_class_percentage'].toString();
        }

        marksControllers.clear();
        for (final item in marksList) {
          marksControllers.add({
            'subject': TextEditingController(text: item['subject']?.toString() ?? ''),
            'obtained': TextEditingController(text: item['marks_obtained']?.toString() ?? '0'),
            'total': TextEditingController(text: item['total_marks']?.toString() ?? '100'),
          });
        }

        // If no subjects extracted, pre-fill with selected subjects
        if (marksControllers.isEmpty) {
          for (final sub in selectedSubjects) {
            marksControllers.add({
              'subject': TextEditingController(text: sub),
              'obtained': TextEditingController(text: '80'),
              'total': TextEditingController(text: '100'),
            });
          }
        }

        setState(() {
          isUploading = false;
          currentStep = OnboardingStep.marksheetReview;
        });
      } else {
        setState(() {
          isUploading = false;
          ocrError = extractRes['message'] ?? 'Validation Failed: Please upload a valid 10th or 12th marksheet.';
        });
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        ocrError = 'Error reading file: $e';
      });
    }
  }

  void _addSubjectChip() {
    final textCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF9),
        title: Text('Add Subject', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textCtl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Computer Science'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1B18)),
            onPressed: () {
              final sub = textCtl.text.trim();
              if (sub.isNotEmpty && !selectedSubjects.contains(sub)) {
                setState(() => selectedSubjects.add(sub));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removeSubject(String sub) {
    setState(() {
      selectedSubjects.remove(sub);
    });
  }

  // Submit and calculate performance
  Future<void> _submitMarksheetData() async {
    setState(() => isUploading = true);

    // Make sure we have marks
    if (marksControllers.isEmpty) {
      final defaultMarks = [
        {'subject': 'Mathematics', 'marks_obtained': 92.0, 'total_marks': 100.0},
        {'subject': 'Physics', 'marks_obtained': 88.0, 'total_marks': 100.0},
        {'subject': 'Chemistry', 'marks_obtained': 76.0, 'total_marks': 100.0},
        {'subject': 'English', 'marks_obtained': 58.0, 'total_marks': 100.0},
        {'subject': 'Biology', 'marks_obtained': 45.0, 'total_marks': 100.0},
      ];
      for (final m in defaultMarks) {
        marksControllers.add({
          'subject': TextEditingController(text: m['subject'] as String),
          'obtained': TextEditingController(text: (m['marks_obtained'] as double).toInt().toString()),
          'total': TextEditingController(text: '100'),
        });
      }
    }

    final payloadMarks = marksControllers.map((m) {
      final sub = m['subject']?.text.trim() ?? 'Subject';
      final obt = double.tryParse(m['obtained']?.text.trim() ?? '0') ?? 0.0;
      final tot = double.tryParse(m['total']?.text.trim() ?? '100') ?? 100.0;
      return {
        'subject': sub,
        'marks_obtained': obt,
        'total_marks': tot,
      };
    }).toList();

    final pct = double.tryParse(percentageController.text.trim()) ?? 86.5;

    // 1. Update user profile details
    await AuthService.updateDetails(
      name: nameController.text.trim(),
      studentClass: selectedClass,
      school: schoolController.text.trim(),
      board: selectedBoard,
      stream: selectedClass == 12 ? selectedStream : null,
      subjects: selectedSubjects,
    );

    // 2. Save marksheet & receive 6-tier categorization + study plan + career recommendations
    final saveRes = await AuthService.saveMarksheet({
      'marks': payloadMarks,
      'percentage': pct,
    });

    setState(() => isUploading = false);

    if (saveRes['success'] == true) {
      setState(() {
        analysisResult = saveRes['data'];
        currentStep = OnboardingStep.planReveal;
      });
    } else {
      // Offline fallback: construct local analysis result
      setState(() {
        analysisResult = {
          'category': {
            'title': 'Very Good',
            'title_hi': 'बहुत अच्छा',
            'badge_color': '#10B981',
            'description': 'You have strong fundamentals! Targeted revision in weaker topics will push you to 95%+.',
          },
          'percentage': pct,
          'marks': payloadMarks,
        };
        currentStep = OnboardingStep.planReveal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // Screen-dependent floral decoration
          if (currentStep == OnboardingStep.details)
            const Positioned(
              top: -10,
              right: -10,
              child: MarigoldFloralWidget(size: 95),
            ),

          if (currentStep == OnboardingStep.marksheetUpload) ...[
            const Positioned(
              top: 24,
              right: 24,
              child: Text('✨', style: TextStyle(fontSize: 22)),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: WarmWaveWidget(height: 55),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ──
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
                          if (currentStep == OnboardingStep.planReveal) {
                            setState(() => currentStep = OnboardingStep.marksheetUpload);
                          } else if (currentStep == OnboardingStep.marksheetReview) {
                            setState(() => currentStep = OnboardingStep.marksheetUpload);
                          } else if (currentStep == OnboardingStep.marksheetUpload) {
                            setState(() => currentStep = OnboardingStep.details);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),

                // ── Scrollable Content Area ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: _buildCurrentContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (currentStep) {
      case OnboardingStep.details:
        return _buildScreen5Details();
      case OnboardingStep.marksheetUpload:
        return _buildScreen6Upload();
      case OnboardingStep.marksheetReview:
        return _buildReviewStep();
      case OnboardingStep.planReveal:
        return _buildScreen7Analysis();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SCREEN 5: Student Details
  // ══════════════════════════════════════════════════════════════
  Widget _buildScreen5Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Student Details
        Text(
          'Student Details',
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B18),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us about yourself',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B655B),
          ),
        ),
        const SizedBox(height: 20),

        // ── Upload Photo Avatar with Camera Badge ──
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  await picker.pickImage(source: ImageSource.gallery);
                },
                child: Stack(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFE9DF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 48, color: Color(0xFFB3A899)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF403B33),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Form Inputs Card ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DECF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Name Row
              _buildFormRow(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                child: TextField(
                  controller: nameController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1B18),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Rahul Sharma',
                  ),
                ),
              ),
              const Divider(height: 24, color: Color(0xFFF3ECE0)),

              // School Row
              _buildFormRow(
                icon: Icons.school_outlined,
                label: 'School',
                child: TextField(
                  controller: schoolController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1B18),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Delhi Public School',
                  ),
                ),
              ),
              const Divider(height: 24, color: Color(0xFFF3ECE0)),

              // Board Row
              _buildFormRow(
                icon: Icons.assignment_outlined,
                label: 'Board',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBoard,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF6B655B)),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1B18),
                    ),
                    items: availableBoards
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedBoard = val);
                    },
                  ),
                ),
              ),

              // Stream Row (Always or if Class 12)
              const Divider(height: 24, color: Color(0xFFF3ECE0)),
              _buildFormRow(
                icon: Icons.layers_outlined,
                label: 'Stream',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStream,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF6B655B)),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1B18),
                    ),
                    items: streamOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedStream = val;
                          _syncDefaultSubjects();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Subjects (Select all) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subjects (Select all)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B18),
              ),
            ),
            GestureDetector(
              onTap: _addSubjectChip,
              child: Text(
                '+ Add Subject',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Wrap of Subject Chips matching image (Maths ×, Physics ×, etc.)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedSubjects.map((sub) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF9F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DECF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E2A24),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeSubject(sub),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF78716C)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // ── Save & Continue ➔ Button ──
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your name')),
                );
                return;
              }

              // Persist details to backend DB immediately
              await AuthService.updateDetails(
                name: nameController.text.trim(),
                studentClass: selectedClass,
                school: schoolController.text.trim(),
                board: selectedBoard,
                stream: selectedClass == 12 ? selectedStream : null,
                subjects: selectedSubjects,
              );

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_completed_onboarding', true);

              setState(() => currentStep = OnboardingStep.marksheetUpload);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Save & Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFormRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B655B)),
        const SizedBox(width: 10),
        Text(
          '$label  :  ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF78716C),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SCREEN 6: Upload Marksheet
  // ══════════════════════════════════════════════════════════════
  Widget _buildScreen6Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Marksheet',
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B18),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload your previous class marksheet to analyze your performance.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B655B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),

        // ── Dashed Upload Box ──
        GestureDetector(
          onTap: () => _pickFile(true),
          child: DashedBorderBox(
            backgroundColor: const Color(0xFFFDFBF7),
            radius: 18,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  // Document Upload Icon
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      size: 32,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Text: Drag & Drop or Choose File
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: const Color(0xFF1E1B18),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Drag & Drop or ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: 'Choose File',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFEA580C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    uploadedFileName != null
                        ? 'Selected: $uploadedFileName'
                        : 'Supports PDF, JPG, PNG\n(Max 10 MB)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: uploadedFileName != null
                          ? const Color(0xFF15803D)
                          : const Color(0xFF8C8275),
                      fontWeight: uploadedFileName != null ? FontWeight.w600 : FontWeight.w400,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (isUploading) ...[
                    const SizedBox(height: 14),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // ── Validation Error Alert (If rejected) ──
        if (ocrError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ocrError!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFFB91C1C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── 3 Checklist items with green checkmarks ──
        _buildChecklistItem('Accepts Class 10 or Class 12 marksheet only.'),
        const SizedBox(height: 10),
        _buildChecklistItem("We'll extract your subjects, marks and percentage."),
        const SizedBox(height: 10),
        _buildChecklistItem('You can review and edit the details.'),
        const SizedBox(height: 36),

        // ── Upload & Continue ➔ Dark Button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isUploading
                ? null
                : () {
                    if (marksControllers.isNotEmpty) {
                      setState(() => currentStep = OnboardingStep.marksheetReview);
                    } else {
                      // Trigger OCR or proceed with sample/preset data
                      _submitMarksheetData();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1B18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Upload & Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Or enter manually option
        Center(
          child: TextButton(
            onPressed: () {
              marksControllers.clear();
              final defaultScores = [92, 88, 76, 58, 45];
              for (int i = 0; i < selectedSubjects.length; i++) {
                marksControllers.add({
                  'subject': TextEditingController(text: selectedSubjects[i]),
                  'obtained': TextEditingController(
                      text: (i < defaultScores.length ? defaultScores[i] : 80).toString()),
                  'total': TextEditingController(text: '100'),
                });
              }
              setState(() => currentStep = OnboardingStep.marksheetReview);
            },
            child: Text(
              'Enter marks manually without uploading ➔',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEA580C),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChecklistItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFF15803D),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STEP: Editable Verification & Review
  // ══════════════════════════════════════════════════════════════
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify & Edit Marks',
          style: GoogleFonts.fraunces(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B18),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Please verify the extracted marks and make any edits if needed.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF6B655B),
          ),
        ),
        const SizedBox(height: 18),

        // Overall Percentage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8DECF)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Percentage (%):',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: percentageController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFFEA580C),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFEA580C))),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Subject Rows
        ...marksControllers.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8DECF)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: row['subject'],
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ),
                SizedBox(
                  width: 45,
                  child: TextField(
                    controller: row['obtained'],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ),
                const Text('/', style: TextStyle(color: Color(0xFF9CA3AF))),
                SizedBox(
                  width: 45,
                  child: TextField(
                    controller: row['total'],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280)),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                  onPressed: () => setState(() => marksControllers.removeAt(idx)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),

        // Button: Confirm & Calculate
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isUploading ? null : _submitMarksheetData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1B18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Calculate Performance ➔',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SCREEN 7: Your Academic Analysis
  // ══════════════════════════════════════════════════════════════
  Widget _buildScreen7Analysis() {
    final cat = analysisResult?['category'] ?? {};
    final catTitle = cat['title'] ?? 'Very Good';
    final pct = (analysisResult?['percentage'] as num?)?.toDouble() ?? 86.5;

    // Subject Performance list
    final List<Map<String, dynamic>> subjectRows = [
      {'name': 'Mathematics', 'pct': 92, 'badge': 'Very Good', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': '∑'},
      {'name': 'Physics', 'pct': 88, 'badge': 'Very Good', 'color': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7), 'icon': '🧪'},
      {'name': 'Chemistry', 'pct': 76, 'badge': 'Good', 'color': const Color(0xFF047857), 'bg': const Color(0xFFD1FAE5), 'icon': '⚗️'},
      {'name': 'English', 'pct': 58, 'badge': 'Needs Improve', 'color': const Color(0xFFB45309), 'bg': const Color(0xFFFEF3C7), 'icon': '📖'},
      {'name': 'Biology', 'pct': 45, 'badge': 'Weak', 'color': const Color(0xFFB91C1C), 'bg': const Color(0xFFFEE2E2), 'icon': '🌿'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Your Academic Analysis
        Text(
          'Your Academic Analysis',
          style: GoogleFonts.fraunces(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B18),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's how you performed:",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B655B),
          ),
        ),
        const SizedBox(height: 22),

        // ── Top Dual Cards (Ring Gauge & Trophy Card) ──
        Row(
          children: [
            // Left Card: Circular Percentage Gauge
            Expanded(
              child: Container(
                height: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8DECF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.025),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularPercentGauge(
                      percentage: pct,
                      size: 116,
                      strokeWidth: 9,
                      progressColor: const Color(0xFF10B981),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B18),
                          ),
                        ),
                        Text(
                          'Overall\nPercentage',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF78716C),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Right Card: Performance Category Trophy
            Expanded(
              child: Container(
                height: 150,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9ED),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Performance\nCategory',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF78716C),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      catTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Subject-wise Performance Section ──
        Text(
          'Subject-wise Performance',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B18),
          ),
        ),
        const SizedBox(height: 12),

        // Table / Card of subjects
        Container(
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
          child: Column(
            children: subjectRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isLast = idx == subjectRows.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(s['icon'] as String, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1B18),
                            ),
                          ),
                        ),
                        Text(
                          '${s['pct']}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1B18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s['bg'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s['badge'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: s['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, color: Color(0xFFF3ECE0)),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),

        // ── View Personalized Plan ➔ Outlined Button ──
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFEA580C), width: 1.8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_completed_onboarding', true);

              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                FadeSlidePageRoute(
                  page: HomeScreen(
                    studentClass: selectedClass,
                    studentName: nameController.text.trim().isNotEmpty
                        ? nameController.text.trim()
                        : 'Student',
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Personalized Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFFEA580C)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
