import re

with open('lib/screens/register_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add state variable
code = code.replace(
    'bool obscureConfirm = true;',
    'bool obscureConfirm = true;\n  bool _accountDetailsValidated = false;'
)

# 2. Add _validateAccountDetails
validate_fn = '''
  void _validateAccountDetails() {
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

    if (!RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
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

    setState(() {
      _accountDetailsValidated = true;
    });
  }
'''
code = code.replace('Future<void> _createAccount() async {', validate_fn + '\n  Future<void> _createAccount() async {')

# 3. Update _createAccount
code = re.sub(
    r'    if \(name\.isEmpty.*?if \(password != confirmPassword\) \{.*?return;\n    \}\n',
    '',
    code,
    flags=re.DOTALL
)

# 4. Update _progress
new_progress = '''  double get _progress {
    if (!_accountDetailsValidated) return 0.16;
    double p = 0.33;
    if (selectedClass == 10 || selectedStream != null) p += 0.16;
    if (selectedWeakSubjects.isNotEmpty) p += 0.16;
    if (_marksheetMode == MarksheetEntryMode.review || _marksheetMode == MarksheetEntryMode.manual) p += 0.16;
    if (goalMinutes > 0) p += 0.16;
    return p.clamp(0.0, 1.0);
  }'''
code = re.sub(r'  double get _progress \{.*?return p\.clamp\(0\.0, 1\.0\);\n  \}', new_progress, code, flags=re.DOTALL)

# 5. Extract Details block
details_match = re.search(r'(                    // ── Details ──\s+FadeSlideIn\(.*?)(                    FadeSlideIn\(\s+key: const ValueKey\(\'login_options\'\))', code, re.DOTALL)
if not details_match:
    print("Could not find Details block")
    exit(1)

# We need to remove it from its original place.
code = code[:details_match.start()] + details_match.group(2) + code[details_match.end():]

# We need to redesign the details block to use NotebookCard, _StepHeader, _LabeledField.
new_details_block = '''
                    // ── Details ──
                    FadeSlideIn(
                      key: const ValueKey('details'),
                      index: 0,
                      child: NotebookCard(
                        ambientGlow: true,
                        padding: const EdgeInsets.fromLTRB(28, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _StepHeader(
                              title: 'Create your account',
                              subtitle: 'Just a few more details',
                            ),
                            _LabeledField(
                              label: 'Full name',
                              child: FocusGlowWrapper(
                                child: TextField(
                                  controller: nameController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: tr(context, 'full_name_hint'),
                                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: 'Email',
                              child: FocusGlowWrapper(
                                child: TextField(
                                  controller: emailController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: tr(context, 'email_hint'),
                                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: 'Password',
                              child: FocusGlowWrapper(
                                child: TextField(
                                  controller: passwordController,
                                  onChanged: (_) => setState(() {}),
                                  obscureText: obscure,
                                  decoration: InputDecoration(
                                    hintText: tr(context, 'password_hint'),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => obscure = !obscure),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LabeledField(
                              label: 'Confirm password',
                              child: FocusGlowWrapper(
                                child: TextField(
                                  controller: confirmPasswordController,
                                  onChanged: (_) => setState(() {}),
                                  obscureText: obscureConfirm,
                                  decoration: InputDecoration(
                                    hintText: tr(context, 'confirm_password_hint'),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (!_accountDetailsValidated) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: PrimaryGlowButton(
                                  child: ElevatedButton(
                                    onPressed: _validateAccountDetails,
                                    child: const Text('Continue'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
'''

# 6. Insert new_details_block right after the header block.
header_match = re.search(r'(FadeSlideIn\(\s+key: const ValueKey\(\'header\'\),.*?const SizedBox\(height: 32\),\s+],\s+\),\s+\),\n)', code, re.DOTALL)
if header_match:
    insert_pos = header_match.end()
    code = code[:insert_pos] + new_details_block + code[insert_pos:]
    
    # 7. Wrap the remaining steps in `if (_accountDetailsValidated) ...[`
    class_sel_pos = code.find('// ── Class selector ──')
    if class_sel_pos != -1:
        code = code[:class_sel_pos] + 'if (_accountDetailsValidated) ...[\n                    ' + code[class_sel_pos:]
        
        # 8. Close the conditional right before `login_options`
        login_opt_pos = code.find("FadeSlideIn(\n                      key: const ValueKey('login_options')")
        if login_opt_pos != -1:
            create_btn_block = '''
                    // ── Submit Button ──
                    FadeSlideIn(
                      key: const ValueKey('submit'),
                      index: 7,
                      child: SizedBox(
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Text(tr(context, 'create_account_btn')),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ], // end if
                    '''
            code = code[:login_opt_pos] + create_btn_block + code[login_opt_pos:]

# 9. Add _StepHeader and _LabeledField at the bottom
helper_classes = '''
class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
'''
code = code + '\n' + helper_classes

# 10. Update Marksheet Step with redesign from previous session.
marksheet_regex = r'(                    // ── Tell us about your last exam ──.*?)(                    // ── Daily study goal ──)'
new_marksheet_block = '''                    // ── Tell us about your last exam ──
                    if (selectedClass == 10 ||
                        (selectedClass == 12 && selectedStream != null))
                      FadeSlideIn(
                        key: const ValueKey('last_exam'),
                        index: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            const _StepHeader(
                              title: 'Upload your marksheet',
                              subtitle: 'So we can spot your weak areas',
                            ),
                            if (_marksheetMode == MarksheetEntryMode.options)
                              DottedBorder(
                                options: RoundedRectDottedBorderOptions(
                                  radius: const Radius.circular(16),
                                  dashPattern: const [8, 4],
                                  color: AppColors.marigoldDeep.withValues(alpha: 0.5),
                                  strokeWidth: 2,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.paperCard,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.document_scanner_rounded,
                                            size: 48,
                                            color: AppColors.marigoldDeep
                                                .withValues(alpha: 0.8)),
                                        const SizedBox(height: 16),
                                        Text(
                                            'Take a photo or upload PDF\\nof your previous class marksheet',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: AppColors.ink,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 24),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 16,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _pickImage(ImageSource.camera),
                                              icon: const Icon(
                                                  Icons.camera_alt_rounded),
                                              label: const Text('Camera'),
                                              style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.marigoldDeep),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () => _pickImage(
                                                  ImageSource.gallery),
                                              icon: const Icon(
                                                  Icons.photo_library_rounded),
                                              label: const Text('Gallery'),
                                              style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.marigoldDeep),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: _pickPdf,
                                              icon: const Icon(
                                                  Icons.picture_as_pdf_rounded),
                                              label: const Text('PDF'),
                                              style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.marigoldDeep),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        TextButton(
                                          onPressed: () => setState(() =>
                                              _marksheetMode =
                                                  MarksheetEntryMode.manual),
                                          child: Text('Enter marks manually',
                                              style: TextStyle(
                                                  color: AppColors.inkSoft,
                                                  decoration: TextDecoration
                                                      .underline)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else if (_marksheetMode ==
                                MarksheetEntryMode.loading)
                              DottedBorder(
                                options: RoundedRectDottedBorderOptions(
                                  radius: const Radius.circular(16),
                                  dashPattern: const [8, 4],
                                  color: AppColors.marigoldDeep.withValues(alpha: 0.5),
                                  strokeWidth: 2,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.paperCard,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const CircularProgressIndicator(
                                            color: AppColors.marigoldDeep),
                                        const SizedBox(height: 16),
                                        Text('Scanning your marksheet...',
                                            style: TextStyle(
                                                color: AppColors.inkSoft,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              NotebookCard(
                                ambientGlow: false,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Verify Details',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: AppColors.ink)),
                                        if (_marksheetMode ==
                                            MarksheetEntryMode.review)
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() => _marksheetMode =
                                                  MarksheetEntryMode.manual);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Switched to manual entry')),
                                              );
                                            },
                                            icon: const Icon(Icons.edit,
                                                size: 16),
                                            label: const Text('Edit Manually'),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...previousTestMarks.map((m) {
                                      final s = m['subject'] as String;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['subject'], style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _obtainedControllers[s],
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (_) => setState(() {}),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Marks obtained',
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text('/', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                                                ),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _totalControllers[s],
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (_) => setState(() {}),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Total max',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(height: 32),
                                    _LabeledField(
                                      label: 'Overall Percentage (%)',
                                      child: TextField(
                                        controller: percentageController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          hintText: 'e.g. 85.5',
                                        ),
                                      ),
                                    ),
                                    if (_marksheetMode ==
                                        MarksheetEntryMode.review) ...[
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() => _marksheetMode =
                                                MarksheetEntryMode.manual);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Marks confirmed!')));
                                          },
                                          icon: const Icon(Icons.check),
                                          label: const Text('Confirm Marks'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
'''
code = re.sub(marksheet_regex, new_marksheet_block + r'\2', code, flags=re.DOTALL)


# 11. Replace _StepHeader in other parts of the form
class_header_regex = r'(Text\(\'Which class are you in\?\',.*?Text\(\'Select your current grade\',.*?\),)'
class_step_header = '''_StepHeader(
                              title: 'Which class are you in?',
                              subtitle: 'Select your current grade',
                            )'''
code = re.sub(class_header_regex, class_step_header, code, flags=re.DOTALL)

stream_header_regex = r'(Text\(\'Select Stream\',.*?Text\(\'For Class 12 students\',.*?\),)'
stream_step_header = '''_StepHeader(
                              title: 'Select Stream',
                              subtitle: 'For Class 12 students',
                            )'''
code = re.sub(stream_header_regex, stream_step_header, code, flags=re.DOTALL)

weak_header_regex = r'(Text\(\'Which subjects need the most help\?\',.*?Text\(\'Select the subjects you want to focus on\',.*?\),)'
weak_step_header = '''_StepHeader(
                              title: 'Which subjects need the most help?',
                              subtitle: 'Select the subjects you want to focus on',
                            )'''
code = re.sub(weak_header_regex, weak_step_header, code, flags=re.DOTALL)

goal_header_regex = r'(Text\(\'Daily study goal\',.*?Text\(\'How much time can you commit daily\?\',.*?\),)'
goal_step_header = '''_StepHeader(
                              title: 'Daily study goal',
                              subtitle: 'How much time can you commit daily?',
                            )'''
code = re.sub(goal_header_regex, goal_step_header, code, flags=re.DOTALL)


with open('lib/screens/register_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
