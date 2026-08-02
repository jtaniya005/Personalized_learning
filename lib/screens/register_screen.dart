import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../widgets/app_logo.dart';
import '../models/mock_data.dart';
import '../widgets/fade_slide_in.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'phone_otp_screen.dart';
import '../services/auth_service.dart';

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
  int selectedAvatar = 0;
  bool obscure = true;
  bool obscureConfirm = true;
  final Set<String> selectedWeakSubjects = {};
  int goalMinutes = 30;
  bool isLoading = false;

  String? selectedStream;
  List<Map<String, dynamic>> previousTestMarks = [];
  final percentageController = TextEditingController();
  List<String> customSubjects = [];

  @override
  void initState() {
    super.initState();
    nameController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    _syncSubjects();
  }

  List<String> _getSubjectsForClassAndStream() {
    if (selectedClass == 10) {
      return ['Mathematics', 'Science', 'Social Science', 'English', 'Hindi', 'Sanskrit', 'Computer Applications/IT'];
    } else if (selectedClass == 12 && selectedStream != null) {
      if (selectedStream == 'Science (PCM)') return ['Physics', 'Chemistry', 'Mathematics', 'English'];
      else if (selectedStream == 'Science (PCB)') return ['Physics', 'Chemistry', 'Biology', 'English'];
      else if (selectedStream == 'Commerce') return ['Accountancy', 'Business Studies', 'Economics', 'English'];
      else if (selectedStream == 'Arts/Humanities') return ['History', 'Political Science', 'Geography', 'Economics', 'English'];
    }
    return [];
  }

  List<String> get _allAvailableSubjects => [..._getSubjectsForClassAndStream(), ...customSubjects];

  void _syncSubjects() {
    final available = _allAvailableSubjects;
    
    selectedWeakSubjects.removeWhere((s) => !available.contains(s));
    previousTestMarks.removeWhere((m) => !available.contains(m['subject']));
    
    final existingSubjects = previousTestMarks.map((m) => m['subject'] as String).toSet();
    for (final s in available) {
      if (!existingSubjects.contains(s)) {
        previousTestMarks.add({'subject': s, 'obtained': '', 'total': ''});
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
    final pct = double.tryParse(percentageController.text);

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
          MaterialPageRoute(
            builder: (_) => HomeScreen(
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
                              const AppLogo(size: 36),
                              const SizedBox(width: 10),
                              Text('Learn Buddy', style: Theme.of(context).textTheme.titleMedium),
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
                        ],
                      ),
                    ),

                    // ── Avatar picker ──
                    FadeSlideIn(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(tr(context, 'pick_avatar'), style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 68,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: avatarOptions.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final a = avatarOptions[i];
                                final isSelected = selectedAvatar == i;
                                return GestureDetector(
                                  onTap: () => setState(() => selectedAvatar = i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: a.gradient),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.ink : Colors.transparent,
                                        width: 3,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: a.gradient.first.withOpacity(0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(a.icon, color: Colors.white, size: 26),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),

                    // ── Class selector ──
                    FadeSlideIn(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(tr(context, 'which_class'),
                              style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 10),
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
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text('Select Stream', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 10),
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
                                      ] : null,
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
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(tr(context, 'weak_subjects'),
                              style: Theme.of(context).textTheme.labelSmall),
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
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.coral.withOpacity(0.16)
                                            : AppColors.paperCard,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected ? AppColors.coral : AppColors.rule,
                                          width: selected ? 1.4 : 1,
                                        ),
                                        boxShadow: selected ? [
                                          BoxShadow(
                                            color: AppColors.coral.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ] : null,
                                      ),
                                      child: Text(s,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: selected ? AppColors.ink : AppColors.inkSoft)),
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
                        index: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text('Tell us about your last exam', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 4),
                            Text('Previous Class Marks (Optional)', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 10),
                            NotebookCard(
                              holeCount: 4,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) => previousTestMarks[idx]['obtained'] = val,
                                              decoration: const InputDecoration(hintText: 'Obtained', isDense: true),
                                            ),
                                          ),
                                          const Text(' / ', style: TextStyle(fontWeight: FontWeight.w600)),
                                          Expanded(
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              onChanged: (val) => previousTestMarks[idx]['total'] = val,
                                              decoration: const InputDecoration(hintText: 'Total', isDense: true),
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
                                  TextField(
                                    controller: percentageController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Overall Percentage (%) - Optional',
                                      prefixIcon: Icon(Icons.percent, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),

                    // ── Daily study goal ──
                    FadeSlideIn(
                      index: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(tr(context, 'daily_goal'),
                              style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 10),
                          NotebookCard(
                            holeCount: 3,
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
                      index: 7,
                      child: NotebookCard(
                holeCount: 6,
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'your_details'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: tr(context, 'full_name_hint'),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: tr(context, 'email_hint'),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
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
                  ],
                ),
                      ),
                    ),
                    FadeSlideIn(
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PhoneOtpScreen(isRegister: true),
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
            ] : null,
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
