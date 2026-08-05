import sys
import io
import re

with io.open('lib/screens/register_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
in_create_account = False
in_details_block = False

for i, line in enumerate(lines):
    if 'bool obscureConfirm = true;' in line:
        new_lines.append(line)
        new_lines.append('  bool _accountDetailsValidated = false;\n')
        continue
        
    if 'Future<void> _createAccount() async {' in line:
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
        new_lines.append(validate_fn + '\n')
        new_lines.append(line)
        in_create_account = True
        continue
        
    if in_create_account:
        if 'if (name.isEmpty || email.isEmpty || password.isEmpty)' in line:
            pass
        elif 'if (!RegExp(' in line:
            pass
        elif 'if (password.length < 8)' in line:
            pass
        elif 'if (password != confirmPassword)' in line:
            pass
        elif 'return;' in line:
            pass
        elif '    setState(() => isLoading = true);' in line:
            in_create_account = False
        else:
            if 'ScaffoldMessenger' not in line and 'const SnackBar' not in line and '      );' not in line and '    }' not in line:
                if not any(x in line for x in ['name.isEmpty', 'RegExp', 'password.length', 'password != confirmPassword']):
                    # Skip 'final name = ...' inside _createAccount because we don't need them anymore since we are not validating
                    if 'final name =' in line or 'final email =' in line or 'final password =' in line or 'final confirmPassword =' in line:
                        pass
                    else:
                        new_lines.append(line)
        continue

    if 'double get _progress {' in line:
        new_progress = '''  double get _progress {
    if (!_accountDetailsValidated) return 0.16;
    double p = 0.33;
    if (selectedClass == 10 || selectedStream != null) p += 0.16;
    if (selectedWeakSubjects.isNotEmpty) p += 0.16;
    if (_marksheetMode == MarksheetEntryMode.review || _marksheetMode == MarksheetEntryMode.manual) p += 0.16;
    if (goalMinutes > 0) p += 0.16;
    return p.clamp(0.0, 1.0);
  }
'''
        new_lines.append(new_progress)
        continue
        
    if 'double p =' in line and 'if (selectedClass' in lines[i+1] and 'return p.clamp' in lines[i+5]:
        continue 
    if 'return p.clamp(0.0, 1.0);' in line and lines[i-1].strip() == 'if (goalMinutes > 0) p += 0.2;':
        continue 
    
    if '// ── Your details ──' in line:
        in_details_block = True
        continue
        
    if in_details_block:
        if 'FadeSlideIn(' in line and 'key: const ValueKey(\'login_options\')' in lines[i+1]:
            in_details_block = False
        else:
            continue
            
    if '// ── Class selector ──' in line:
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
                    if (_accountDetailsValidated) ...[
'''
        new_lines.append(new_details_block)
        new_lines.append(line)
        continue
        
    if 'FadeSlideIn(' in line and 'key: const ValueKey(\'login_options\')' in lines[i+1]:
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
                    ], // end if (_accountDetailsValidated)
'''
        new_lines.append(create_btn_block)
        new_lines.append(line)
        continue

    if '// ── Tell us about your last exam ──' in line:
        marksheet = '''                    // ── Tell us about your last exam ──
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
        new_lines.append(marksheet)
        continue
    
    if 'Text(\'Which class are you in?\'' in line:
        new_lines.append('''                            const _StepHeader(
                              title: 'Which class are you in?',
                              subtitle: 'Select your current grade',
                            ),\n''')
        continue
    if 'Text(\'Select your current grade\'' in line:
        continue

    if 'Text(\'Select Stream\'' in line:
        new_lines.append('''                            const _StepHeader(
                              title: 'Select Stream',
                              subtitle: 'For Class 12 students',
                            ),\n''')
        continue
    if 'Text(\'For Class 12 students\'' in line:
        continue

    if 'Text(\'Which subjects need the most help?\'' in line:
        new_lines.append('''                            const _StepHeader(
                              title: 'Which subjects need the most help?',
                              subtitle: 'Select the subjects you want to focus on',
                            ),\n''')
        continue
    if 'Text(\'Select the subjects you want to focus on\'' in line:
        continue
        
    if 'Text(\'Daily study goal\'' in line:
        new_lines.append('''                            const _StepHeader(
                              title: 'Daily study goal',
                              subtitle: 'How much time can you commit daily?',
                            ),\n''')
        continue
    if 'Text(\'How much time can you commit daily?\'' in line:
        continue
    
    new_lines.append(line)

text = ''.join(new_lines)

text = re.sub(
    r'(?s)(                    // ── Tell us about your last exam ──.*?)(                    if \(selectedClass == 10 \|\|.*?)(                    // ── Daily study goal ──)',
    r'\1\3',
    text
)

# Replace 'setState(() => isLoading = true);' with '    setState(() => isLoading = true);' safely since we removed lines before it
text = text.replace('    setState(() => isLoading = true);', '    setState(() => isLoading = true);')

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
if '_StepHeader' not in text[text.rfind('}'):]: 
    text = text + '\n' + helper_classes

with io.open('lib/screens/register_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
