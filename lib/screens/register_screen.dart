import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../widgets/app_logo.dart';
import '../models/mock_data.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/focus_glow_wrapper.dart';
import '../widgets/primary_glow_button.dart';
import '../widgets/animated_scale_press.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'phone_otp_screen.dart';
import '../widgets/page_transitions.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';
import '../services/auth_service.dart';

enum MarksheetEntryMode { options, loading, review, manual }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  int selectedClass = 10;
  final int selectedAvatar = 0;
  bool obscure = true;
  bool obscureConfirm = true;
  final Set<String> selectedWeakSubjects = {};
  int goalMinutes = 30;
  bool isLoading = false;

  String? selectedStream;
  List<Map<String, dynamic>> previousTestMarks = [];
  final percentageController = TextEditingController();
  List<String> customSubjects = [];
  
  MarksheetEntryMode _marksheetMode = MarksheetEntryMode.options;
  
  final Map<String, TextEditingController> _obtainedControllers = {};
  final Map<String, TextEditingController> _totalControllers = {};

  @override
  void initState() {
    super.initState();
    _syncSubjects();
  }

  List<String> _getSubjectsForClassAndStream() {
    if (selectedClass == 10) {
      return ['Mathematics', 'Science', 'Social Science', 'English', 'Hindi', 'Computer Applications/IT'];
    } else if (selectedClass == 12 && selectedStream != null) {
      if (selectedStream == 'Science (PCM)') return ['Physics', 'Chemistry', 'Mathematics', 'English'];
      else if (selectedStream == 'Science (PCB)') return ['Physics', 'Chemistry', 'Biology', 'English'];
      else if (selectedStream == 'Commerce') return ['Accountancy', 'Business Studies', 'Economics', 'English'];
      else if (selectedStream == 'Arts/Humanities') return ['History', 'Political Science', 'Geography', 'Economics', 'English'];
    }
    return [];
  }

  IconData _getSubjectIcon(String subjectName) {
    switch (subjectName) {
      case 'Mathematics': return Icons.calculate_rounded;
      case 'Science': return Icons.science_rounded;
      case 'Social Science': return Icons.public_rounded;
      case 'English': return Icons.menu_book_rounded;
      case 'Hindi': return Icons.translate_rounded;
      case 'Computer Applications/IT': return Icons.computer_rounded;
      case 'Physics': return Icons.biotech_rounded;
      case 'Chemistry': return Icons.science_rounded;
      case 'Biology': return Icons.eco_rounded;
      case 'Accountancy': return Icons.account_balance_wallet_rounded;
      case 'Business Studies': return Icons.business_center_rounded;
      case 'Economics': return Icons.trending_up_rounded;
      case 'History': return Icons.history_edu_rounded;
      case 'Political Science': return Icons.gavel_rounded;
      case 'Geography': return Icons.map_rounded;
      default: return Icons.book_rounded;
    }
  }

  double _calculateProgress() {
    double p = 0.2;
    if (selectedClass == 12 && selectedStream != null) {
      p += 0.1;
    } else if (selectedClass == 10) {
      p += 0.1;
    }
    
    if (selectedWeakSubjects.isNotEmpty) p += 0.2;
    if (previousTestMarks.any((m) => m['obtained'].toString().trim().isNotEmpty)) p += 0.2;
    p += 0.1;
    
    if (nameController.text.trim().isNotEmpty && emailController.text.trim().isNotEmpty && passwordController.text.trim().isNotEmpty) p += 0.2;
    
    return p.clamp(0.0, 1.0);
  }

  List<String> get _allAvailableSubjects => [..._getSubjectsForClassAndStream(), ...customSubjects];

  void _syncSubjects() {
    final available = _allAvailableSubjects;
    
    selectedWeakSubjects.removeWhere((s) => !available.contains(s));
    previousTestMarks.removeWhere((m) => !available.contains(m['subject']));
    
    // Clean up old controllers
    _obtainedControllers.removeWhere((k, v) => !available.contains(k));
    _totalControllers.removeWhere((k, v) => !available.contains(k));
    
    final existingSubjects = previousTestMarks.map((m) => m['subject'] as String).toSet();
    for (final s in available) {
      if (!existingSubjects.contains(s)) {
        previousTestMarks.add({'subject': s, 'obtained': '', 'total': '100'});
        _obtainedControllers[s] = TextEditingController(text: '');
        _totalControllers[s] = TextEditingController(text: '100');
      } else {
        if (!_obtainedControllers.containsKey(s)) {
           final m = previousTestMarks.firstWhere((x) => x['subject'] == s);
           _obtainedControllers[s] = TextEditingController(text: m['obtained'].toString());
           _totalControllers[s] = TextEditingController(text: m['total'].toString());
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      _processMarksheet(pickedFile.path, isPdf: false);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      _processMarksheet(result.files.single.path!, isPdf: true);
    }
  }

  Future<void> _processMarksheet(String filePath, {required bool isPdf}) async {
    setState(() => _marksheetMode = MarksheetEntryMode.loading);
    
    String imagePath = filePath;
    try {
      if (isPdf) {
        final document = await PdfDocument.openFile(filePath);
        final page = await document.getPage(1);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );
        await page.close();
        await document.close();
        
        if (pageImage != null) {
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/temp_marksheet.png');
          await tempFile.writeAsBytes(pageImage.bytes);
          imagePath = tempFile.path;
        } else {
          throw Exception('Failed to render PDF page');
        }
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      
      // TODO: The original uploaded marksheet image should be treated as sensitive
      // personal data. The backend integration for storing this (if we want to keep
      // the original file) needs its own private, per-student bucket — separate from
      // rag-documents. Leave actual upload-to-backend as a TODO for now.

      _parseExtractedText(recognizedText.text);
      
      if (mounted) {
        setState(() => _marksheetMode = MarksheetEntryMode.review);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t quite read that — let\'s enter it manually')),
        );
        setState(() => _marksheetMode = MarksheetEntryMode.manual);
      }
    }
  }

  void _parseExtractedText(String text) {
    final availableSubjects = _allAvailableSubjects;
    final lines = text.split('\n');
    final Map<String, Map<String, String>> extractedMarks = {};

    for (final line in lines) {
       for (final subject in availableSubjects) {
          final normalizedSubject = subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final normalizedLine = line.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
          
          bool matches = normalizedLine.contains(normalizedSubject);
          if (!matches && normalizedSubject == 'mathematics' && normalizedLine.contains('maths')) matches = true;
          if (!matches && normalizedSubject == 'science' && normalizedLine.contains('science')) matches = true;
          if (!matches && normalizedSubject == 'socialscience' && (normalizedLine.contains('social') || normalizedLine.contains('sst'))) matches = true;
          
          if (matches) {
             final numbers = RegExp(r'\b\d{1,3}\b').allMatches(line).map((m) => m.group(0)!).toList();
             if (numbers.isNotEmpty) {
                 String obtained = '';
                 String total = '';
                 if (numbers.length >= 2) {
                     int n1 = int.parse(numbers[numbers.length - 2]);
                     int n2 = int.parse(numbers[numbers.length - 1]);
                     if (n1 <= n2) {
                        obtained = n1.toString();
                        total = n2.toString();
                     } else {
                        obtained = n2.toString();
                        total = n1.toString();
                     }
                 } else if (numbers.length == 1) {
                     obtained = numbers[0];
                 }
                 extractedMarks[subject] = {'obtained': obtained, 'total': total};
             }
          }
       }
    }

    if (extractedMarks.isEmpty) {
        throw Exception("No marks parsed");
    }

    for (int i = 0; i < previousTestMarks.length; i++) {
       final sub = previousTestMarks[i]['subject'];
       if (extractedMarks.containsKey(sub)) {
           final obtained = extractedMarks[sub]!['obtained']!;
           previousTestMarks[i]['obtained'] = obtained;
           _obtainedControllers[sub]?.text = obtained;
           if (extractedMarks[sub]!['total']!.isNotEmpty) {
             final total = extractedMarks[sub]!['total']!;
             previousTestMarks[i]['total'] = total;
             _totalControllers[sub]?.text = total;
           }
       }
    }
  }

  void _onClassChanged(int newClass) {
    setState(() {
      selectedClass = newClass;
      if (newClass == 10) selectedStream = null;
      _syncSubjects();
    });
  }

  void _onStreamChanged(String newStream) {
    setState(() {
      selectedStream = newStream;
      _syncSubjects();
    });
  }

  void _addCustomSubject() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Physical Education'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty && !customSubjects.contains(val) && !_getSubjectsForClassAndStream().contains(val)) {
                setState(() {
                  customSubjects.add(val);
                  selectedWeakSubjects.add(val);
                  _syncSubjects();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  double get _progress {
    double p = 0.2;
    if (selectedClass == 10 || selectedStream != null) p += 0.2;
    if (selectedWeakSubjects.isNotEmpty) p += 0.2;
    if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.isNotEmpty) p += 0.4;
    return p.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    percentageController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => isLoading = true);

    final parsedMarks = previousTestMarks
        .where((m) => m['obtained'].toString().isNotEmpty)
        .map((m) => {
              'subject': m['subject'],
              'marksObtained': double.tryParse(m['obtained'].toString()),
              'totalMarks': double.tryParse(m['total'].toString()),
            })
        .toList();
        
    double? pct = double.tryParse(percentageController.text);
    if (pct == null && parsedMarks.isNotEmpty) {
      double totalObtained = 0;
      double totalMax = 0;
      bool hasValidMarks = false;
      for (var m in parsedMarks) {
        if (m['marksObtained'] != null && m['totalMarks'] != null && (m['totalMarks'] as double) > 0) {
          totalObtained += m['marksObtained'] as double;
          totalMax += m['totalMarks'] as double;
          hasValidMarks = true;
        }
      }
      if (hasValidMarks && totalMax > 0) {
        pct = (totalObtained / totalMax) * 100;
        pct = double.parse(pct.toStringAsFixed(1));
      }
    }

    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
      studentClass: selectedClass,
      avatarIndex: selectedAvatar,
      weakSubjects: selectedWeakSubjects.toList(),
      dailyGoalMinutes: goalMinutes,
      stream: selectedStream,
      previousTestMarks: parsedMarks,
      previousClassPercentage: pct,
    );

    if (mounted) {
      setState(() => isLoading = false);
    }

    if (result['success']) {
      weakSubjectsNotifier.value = selectedWeakSubjects.toList();
      dailyGoalMinutes.value = goalMinutes;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          FadeSlidePageRoute(
            page: HomeScreen(
              studentClass: selectedClass,
              studentName: name.isEmpty ? 'Student' : name,
              avatarIndex: selectedAvatar,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.paperCard,
              color: AppColors.coral,
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      key: const ValueKey('header'),
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.paperCard,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.rule),
                                  ),
                                  child: Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.inkSoft),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.9 + (0.1 * value),
                                      alignment: Alignment.centerLeft,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const AppLogo(size: 36),
                                    const SizedBox(width: 10),
                                    Text('Learn Buddy', style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(tr(context, 'register_title'),
                              style: Theme.of(context).textTheme.displayLarge),
                          const SizedBox(height: 8),
                          Text(
                            tr(context, 'register_sub'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          
                          // Progress Bar
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: _calculateProgress()),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Registration Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                                      Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.marigoldDeep)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      minHeight: 6,
                                      backgroundColor: AppColors.rule,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.marigold),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // ── Class selector ──
                    FadeSlideIn(
                      key: const ValueKey('class_selector'),
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Icon(Icons.school_rounded, size: 18, color: AppColors.marigoldDeep),
                              const SizedBox(width: 8),
                              Text(tr(context, 'which_class'),
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _ClassChip(
                                label: 'Class 10',
                                selected: selectedClass == 10,
                                onTap: () => _onClassChanged(10),
                              ),
                              const SizedBox(width: 12),
                              _ClassChip(
                                label: 'Class 12',
                                selected: selectedClass == 12,
                                onTap: () => _onClassChanged(12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),

                    if (selectedClass == 12)
                      FadeSlideIn(
                        key: const ValueKey('stream_selector'),
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Icon(Icons.science_rounded, size: 18, color: AppColors.marigoldDeep),
                                const SizedBox(width: 8),
                                Text('Select Stream', style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: ['Science (PCM)', 'Science (PCB)', 'Commerce', 'Arts/Humanities'].map((s) {
                                final selected = selectedStream == s;
                                return GestureDetector(
                                  onTap: () => _onStreamChanged(s),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.marigold : AppColors.paperCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected ? AppColors.marigoldDeep : AppColors.rule,
                                        width: selected ? 1.5 : 1.0,
                                      ),
                                      boxShadow: selected ? [
                                        BoxShadow(
                                          color: AppColors.marigold.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ] : [
                                        BoxShadow(
                                          color: AppColors.ink.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: selected ? AppColors.ink : AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),

                    // ── Weak subjects ──
                    FadeSlideIn(
                      key: const ValueKey('weak_subjects'),
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Icon(Icons.flag_rounded, size: 18, color: AppColors.coral),
                              const SizedBox(width: 8),
                              Text(tr(context, 'weak_subjects'),
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(tr(context, 'weak_subjects_sub'),
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 10),
                          if (selectedClass == 12 && selectedStream == null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.paperCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.rule),
                              ),
                              child: Text('Please select your stream first to see subjects.', style: TextStyle(color: AppColors.inkSoft)),
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ..._allAvailableSubjects.map((s) {
                                  final selected = selectedWeakSubjects.contains(s);
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      if (selected) {
                                        selectedWeakSubjects.remove(s);
                                      } else {
                                        selectedWeakSubjects.add(s);
                                      }
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.teal.withOpacity(0.22)
                                            : AppColors.paperCard,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected ? AppColors.teal : AppColors.rule,
                                          width: selected ? 1.5 : 1,
                                        ),
                                        boxShadow: selected ? [
                                          BoxShadow(
                                            color: AppColors.teal.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ] : [
                                          BoxShadow(
                                            color: AppColors.ink.withOpacity(0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_getSubjectIcon(s), size: 16, color: selected ? AppColors.teal : AppColors.inkSoft),
                                          const SizedBox(width: 6),
                                          Text(s,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: selected ? AppColors.ink : AppColors.inkSoft)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                GestureDetector(
                                  onTap: _addCustomSubject,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.rule, style: BorderStyle.solid),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded, size: 16, color: AppColors.inkSoft),
                                        const SizedBox(width: 4),
                                        Text('Add Subject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.inkSoft)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),

                    if (selectedClass == 10 || (selectedClass == 12 && selectedStream != null))
                      FadeSlideIn(
                        key: const ValueKey('last_exam'),
                        index: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.teal),
                                const SizedBox(width: 8),
                                Text('Tell us about your last exam', style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Previous Class Marks (Optional)', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 10),
                            if (_marksheetMode == MarksheetEntryMode.options)
                              NotebookCard(
                                holeCount: 4,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Icon(Icons.document_scanner_outlined, size: 48, color: AppColors.coral),
                                    const SizedBox(height: 12),
                                    Text('Upload your marksheet', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 6),
                                    Text('We will extract the marks for you.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _pickImage(ImageSource.camera),
                                            icon: Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.ink),
                                            label: Text('Camera', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              side: BorderSide(color: AppColors.rule),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _pickImage(ImageSource.gallery),
                                            icon: Icon(Icons.photo_outlined, size: 20, color: AppColors.ink),
                                            label: Text('Gallery', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              side: BorderSide(color: AppColors.rule),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _pickPdf,
                                        icon: Icon(Icons.picture_as_pdf_outlined, size: 20, color: AppColors.ink),
                                        label: Text('Upload PDF', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: BorderSide(color: AppColors.rule),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () => setState(() => _marksheetMode = MarksheetEntryMode.manual),
                                      child: Text('Enter marks manually instead', style: TextStyle(color: AppColors.inkSoft)),
                                    ),
                                  ],
                                ),
                              )
                            else if (_marksheetMode == MarksheetEntryMode.loading)
                              NotebookCard(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(color: AppColors.coral),
                                      const SizedBox(height: 16),
                                      Text('Reading your marksheet...', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              )
                            else if (_marksheetMode == MarksheetEntryMode.review || _marksheetMode == MarksheetEntryMode.manual)
                              NotebookCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_marksheetMode == MarksheetEntryMode.review) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: AppColors.marigold.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.marigoldDeep.withOpacity(0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_outline, color: AppColors.marigoldDeep, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text('We found this — does it look right?', style: TextStyle(color: AppColors.marigoldDeep, fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    ...previousTestMarks.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final m = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(m['subject'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: FocusGlowWrapper(
                                                child: TextField(
                                                  controller: _obtainedControllers[m['subject']],
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) => previousTestMarks[idx]['obtained'] = val,
                                                  decoration: const InputDecoration(hintText: 'Obtained', isDense: true),
                                                ),
                                              ),
                                            ),
                                            const Text(' / ', style: TextStyle(fontWeight: FontWeight.w600)),
                                            Expanded(
                                              child: FocusGlowWrapper(
                                                child: TextField(
                                                  controller: _totalControllers[m['subject']],
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) => previousTestMarks[idx]['total'] = val,
                                                  decoration: const InputDecoration(hintText: 'Total', isDense: true),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    TextButton.icon(
                                      onPressed: _addCustomSubject,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Subject'),
                                    ),
                                    const SizedBox(height: 16),
                                    FocusGlowWrapper(
                                      child: TextField(
                                        controller: percentageController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          hintText: 'Overall Percentage (%) - Optional',
                                          prefixIcon: Icon(Icons.percent, size: 20),
                                        ),
                                      ),
                                    ),
                                    if (_marksheetMode == MarksheetEntryMode.review) ...[
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: PrimaryGlowButton(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() => _marksheetMode = MarksheetEntryMode.manual);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks confirmed!')));
                                            },
                                            icon: const Icon(Icons.check),
                                            label: const Text('Confirm Marks'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),

                    // ── Daily study goal ──
                    FadeSlideIn(
                      key: const ValueKey('daily_goal'),
                      index: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 18, color: AppColors.grape),
                              const SizedBox(width: 8),
                              Text(tr(context, 'daily_goal'),
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 12),
                          NotebookCard(
                            child: Row(
                              children: [
                                _GoalStepButton(
                                  icon: Icons.remove_rounded,
                                  onTap: goalMinutes > 10
                                      ? () => setState(() => goalMinutes -= 10)
                                      : null,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('$goalMinutes',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(fontSize: 26, color: AppColors.marigoldDeep)),
                                      Text(tr(context, 'min_per_day'),
                                          style: Theme.of(context).textTheme.labelSmall),
                                    ],
                                  ),
                                ),
                                _GoalStepButton(
                                  icon: Icons.add_rounded,
                                  onTap: goalMinutes < 180
                                      ? () => setState(() => goalMinutes += 10)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                    
                    // ── Details ──
                    FadeSlideIn(
                      key: const ValueKey('details'),
                      index: 7,
              child: NotebookCard(
                ambientGlow: true,
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 18, color: AppColors.skyInk),
                        const SizedBox(width: 8),
                        Text(tr(context, 'your_details'), style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FocusGlowWrapper(
                      child: TextField(
                        controller: nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: tr(context, 'full_name_hint'),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FocusGlowWrapper(
                      child: TextField(
                        controller: emailController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: tr(context, 'email_hint'),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FocusGlowWrapper(
                      child: TextField(
                        controller: passwordController,
                        onChanged: (_) => setState(() {}),
                        obscureText: obscure,
                        decoration: InputDecoration(
                          hintText: tr(context, 'password_hint'),
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FocusGlowWrapper(
                      child: TextField(
                        controller: confirmPasswordController,
                        onChanged: (_) => setState(() {}),
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          hintText: tr(context, 'confirm_password_hint'),
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryGlowButton(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _createAccount,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(tr(context, 'create_account_btn')),
                        ),
                      ),
                    ),
                  ],
                ),
                      ),
                    ),
                    FadeSlideIn(
                      key: const ValueKey('login_options'),
                      index: 8,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.rule)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(tr(context, 'or_signup_with'),
                                    style: Theme.of(context).textTheme.labelSmall),
                              ),
                              Expanded(child: Divider(color: AppColors.rule)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedScalePress(
                                  child: OutlinedButton.icon(
                                    onPressed: _createAccount,
                                    icon: Icon(Icons.g_mobiledata_rounded,
                                        size: 22, color: AppColors.ink),
                                    label: Text(tr(context, 'google'),
                                        style: TextStyle(
                                            color: AppColors.ink, fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      side: BorderSide(color: AppColors.rule),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedScalePress(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      FadeSlidePageRoute(
                                        page: const PhoneOtpScreen(isRegister: true),
                                      ),
                                    ),
                                    icon: Icon(Icons.phone_android_rounded,
                                        size: 20, color: AppColors.ink),
                                    label: Text(tr(context, 'phone_otp'),
                                        style: TextStyle(
                                            color: AppColors.ink, fontWeight: FontWeight.w600)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      side: BorderSide(color: AppColors.rule),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(text: tr(context, 'already_have_account')),
                                  TextSpan(
                                    text: tr(context, 'login_link'),
                                    style: const TextStyle(
                                      color: AppColors.skyInk,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    recognizer: (TapGestureRecognizer()
                                      ..onTap = () => Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (_) => const LoginScreen()))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _GoalStepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.rule.withOpacity(0.4) : AppColors.paper,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.rule),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? AppColors.inkSoft : AppColors.ink),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ClassChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.marigold : AppColors.paperCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.marigoldDeep : AppColors.rule,
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: selected ? [
              BoxShadow(
                color: AppColors.marigold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [
              BoxShadow(
                color: AppColors.ink.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
