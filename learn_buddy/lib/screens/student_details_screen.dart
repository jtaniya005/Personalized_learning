import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../widgets/primary_glow_button.dart';
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

  // Step 1: Details
  final nameController = TextEditingController();
  final schoolController = TextEditingController();
  int selectedClass = 10;
  String selectedBoard = 'CBSE';
  String? selectedStream;
  List<String> selectedSubjects = [];

  final List<String> availableBoards = [
    'CBSE',
    'ICSE / ISC',
    'State Board (UP / Bihar / MP / Other)',
    'Maharashtra State Board',
    'Other'
  ];

  final List<String> streamOptions = [
    'Science (PCM)',
    'Science (PCB)',
    'Science (PCMB)',
    'Commerce',
    'Arts / Humanities'
  ];

  // Step 2 & 3: Marksheet
  bool isUploading = false;
  String? uploadedFileName;
  String? ocrError;
  List<String> ocrWarnings = [];
  final percentageController = TextEditingController();
  List<Map<String, TextEditingController>> marksControllers = [];

  // Step 4: Results
  Map<String, dynamic>? analysisResult;

  @override
  void initState() {
    super.initState();
    _populateInitialData();
  }

  void _populateInitialData() {
    final user = widget.initialUser ?? AuthService.currentUser;
    if (user != null) {
      nameController.text = user['name'] ?? '';
      schoolController.text = user['school'] ?? '';
      selectedClass = user['student_class'] as int? ?? 10;
      selectedBoard = user['board'] ?? 'CBSE';
      selectedStream = user['stream'];
    }
    _syncSubjects();
  }

  void _syncSubjects() {
    final list = getSubjectsForClassAndStream(selectedClass, selectedStream);
    setState(() {
      selectedSubjects = List.from(list);
    });
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

  // Pick Marksheet PDF or Image
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

      // Call Backend Marksheet Extract & Validation
      final extractRes = await AuthService.extractMarksheet(fileBytes, fileName);

      if (extractRes['success'] == true) {
        final data = extractRes['data'];
        final marksList = data['marks'] as List? ?? [];

        // Set warnings
        if (data['warnings'] != null) {
          ocrWarnings = List<String>.from(data['warnings']);
        }

        // Set percentage
        if (data['previous_class_percentage'] != null) {
          percentageController.text = data['previous_class_percentage'].toString();
        }

        // Populate editable controllers
        marksControllers.clear();
        for (final item in marksList) {
          marksControllers.add({
            'subject': TextEditingController(text: item['subject']?.toString() ?? ''),
            'obtained': TextEditingController(text: item['marks_obtained']?.toString() ?? '0'),
            'total': TextEditingController(text: item['total_marks']?.toString() ?? '100'),
          });
        }

        // If no subjects found, default with enrolled subjects
        if (marksControllers.isEmpty) {
          for (final sub in selectedSubjects) {
            marksControllers.add({
              'subject': TextEditingController(text: sub),
              'obtained': TextEditingController(text: '75'),
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

  void _addSubjectRow() {
    setState(() {
      marksControllers.add({
        'subject': TextEditingController(text: ''),
        'obtained': TextEditingController(text: '80'),
        'total': TextEditingController(text: '100'),
      });
    });
  }

  void _removeSubjectRow(int index) {
    setState(() {
      marksControllers.removeAt(index);
    });
  }

  // Save Marksheet & Generate Plan
  Future<void> _submitMarksheetData() async {
    if (marksControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject with marks')),
      );
      return;
    }

    setState(() => isUploading = true);

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

    final pct = double.tryParse(percentageController.text.trim());

    // Update details first
    await AuthService.updateDetails(
      name: nameController.text.trim(),
      studentClass: selectedClass,
      school: schoolController.text.trim(),
      board: selectedBoard,
      stream: selectedStream,
      subjects: selectedSubjects,
    );

    // Save marksheet & receive 6-tier categorization + study plan + career options
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveRes['message'] ?? 'Failed to save marks')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          currentStep == OnboardingStep.details
              ? 'Student Profile Setup'
              : (currentStep == OnboardingStep.marksheetUpload
                  ? 'Upload Marksheet'
                  : (currentStep == OnboardingStep.marksheetReview
                      ? 'Verify & Edit Marks'
                      : 'Your Learning Pathway')),
        ),
        automaticallyImplyLeading: currentStep != OnboardingStep.planReveal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _buildCurrentStepContent(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case OnboardingStep.details:
        return _buildDetailsStep();
      case OnboardingStep.marksheetUpload:
        return _buildMarksheetUploadStep();
      case OnboardingStep.marksheetReview:
        return _buildMarksheetReviewStep();
      case OnboardingStep.planReveal:
        return _buildPlanRevealStep();
    }
  }

  // STEP 1: Academic Details
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotebookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 1 of 3: Your Academic Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('We customize your AI Mentor and curriculum based on your syllabus.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const Divider(height: 28),

              // Full Name
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: AppColors.paperCard,
                ),
              ),
              const SizedBox(height: 18),

              // Class Selection (10th or 12th)
              const Text('Current Class', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [10, 12].map((c) {
                  final isSelected = selectedClass == c;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedClass = c;
                            if (c == 10) selectedStream = null;
                            _syncSubjects();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.marigold : AppColors.paperCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.ink : AppColors.rule,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Class $c',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Stream (Only if Class 12)
              if (selectedClass == 12) ...[
                const Text('Select Stream', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStream ?? streamOptions.first,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.paperCard,
                  ),
                  items: streamOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedStream = val;
                      _syncSubjects();
                    });
                  },
                ),
                const SizedBox(height: 18),
              ],

              // Board
              const Text('Education Board', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedBoard,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.paperCard,
                ),
                items: availableBoards.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedBoard = val);
                },
              ),
              const SizedBox(height: 18),

              // School Name
              const Text('School / College Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  hintText: 'e.g. Kendriya Vidyalaya / DPS',
                  prefixIcon: const Icon(Icons.school_outlined),
                  filled: true,
                  fillColor: AppColors.paperCard,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: PrimaryGlowButton(
            child: ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your full name')),
                  );
                  return;
                }
                setState(() => currentStep = OnboardingStep.marksheetUpload);
              },
              child: const Text('Next: Upload Marksheet 📄'),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Marksheet Upload & Validation
  Widget _buildMarksheetUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotebookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 2 of 3: Marksheet Verification',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Upload your previous class (Class ${selectedClass == 10 ? 9 : 10}/11th) marksheet. Our OCR engine validates and extracts your subject-wise marks.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Validation Check: Only Class 10th/12th (or previous class) marksheets are accepted. Other documents will be rejected automatically.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              if (ocrError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ocrError!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (isUploading) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.marigold),
                      SizedBox(height: 14),
                      Text('Analyzing document with OCR & checking 10th/12th validation...',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFile(false),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Upload Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFile(true),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Upload PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Manual entry fallback
                      marksControllers.clear();
                      for (final sub in selectedSubjects) {
                        marksControllers.add({
                          'subject': TextEditingController(text: sub),
                          'obtained': TextEditingController(text: '75'),
                          'total': TextEditingController(text: '100'),
                        });
                      }
                      setState(() => currentStep = OnboardingStep.marksheetReview);
                    },
                    child: const Text('Or enter marks manually without uploading ✍️'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: Verify & Edit Extracted Marks
  Widget _buildMarksheetReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotebookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 3 of 3: Verify Extracted Marks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Check the marks below. If any mark or subject was read incorrectly, edit it right here before saving.'),
              const Divider(height: 24),

              if (ocrWarnings.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ocrWarnings.map((w) => Text('• $w', style: const TextStyle(fontSize: 12, color: Colors.deepOrange))).toList(),
                  ),
                ),
              ],

              // Percentage Field
              Row(
                children: [
                  const Text('Overall Percentage (%):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: percentageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 85',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: AppColors.paperCard,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subject Rows (Editable)
              const Text('Subject-wise Marks (Editable):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: marksControllers.length,
                itemBuilder: (ctx, idx) {
                  final row = marksControllers[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paperCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.rule),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: row['subject'],
                            decoration: const InputDecoration(
                              hintText: 'Subject',
                              isDense: true,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: row['obtained'],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Obtained',
                              isDense: true,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('/'),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: row['total'],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '100',
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => _removeSubjectRow(idx),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addSubjectRow,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Subject'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (isUploading)
          const Center(child: CircularProgressIndicator(color: AppColors.marigold))
        else
          SizedBox(
            width: double.infinity,
            child: PrimaryGlowButton(
              child: ElevatedButton(
                onPressed: _submitMarksheetData,
                child: const Text('Calculate Performance & Generate Plan 🚀'),
              ),
            ),
          ),
      ],
    );
  }

  // STEP 4: 6-Tier Categorization & Study Plan Reveal!
  Widget _buildPlanRevealStep() {
    final cat = analysisResult?['category'] ?? {};
    final catTitle = cat['title'] ?? 'Strong';
    final catTitleHi = cat['title_hi'] ?? 'अच्छा';
    final badgeColorHex = cat['badge_color'] ?? '#2196F3';
    final badgeColor = Color(int.parse(badgeColorHex.replaceAll('#', '0xff')));
    final desc = cat['description'] ?? '';
    final plan = analysisResult?['study_plan'] ?? {};
    final careerRecs = (analysisResult?['career_recommendations'] as List? ?? []);
    final weakSubs = (analysisResult?['weak_subjects'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: badgeColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      catTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    catTitleHi,
                    style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(desc, style: const TextStyle(fontSize: 14)),
              if (weakSubs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Focus Priority Subjects (<60%): ${weakSubs.join(', ')}',
                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Study Plan Card
        NotebookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.marigold),
                  const SizedBox(width: 8),
                  Text('Personalized Study Roadmap',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(plan['strategy'] ?? 'Consistent daily revision and practice.',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              const Divider(height: 20),

              const Text('Daily Recommended Routine:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ...((plan['daily_schedule'] as List? ?? []).map((slot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.paperCard,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(slot['time'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(slot['activity'] ?? '', style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                );
              })),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Career Options Grounded via Pinecone
        NotebookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore_outlined, color: AppColors.coral),
                  const SizedBox(width: 8),
                  Text('Top Career Pathways (AI Grounded)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Matched with your stream & subject strengths from Pinecone:', style: TextStyle(fontSize: 12)),
              const Divider(height: 20),

              ...careerRecs.take(3).map((car) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.paperCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.rule),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(car['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(car['description'] ?? '', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: PrimaryGlowButton(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      studentClass: selectedClass,
                      studentName: nameController.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text('Enter My Learn Buddy Dashboard 🎉'),
            ),
          ),
        ),
      ],
    );
  }
}
