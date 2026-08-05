import re

with open('lib/screens/register_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add _accountDetailsValidated
code = re.sub(r'(bool obscureConfirm = true;)', r'\1\n  bool _accountDetailsValidated = false;', code)

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

# 3. Remove validation from _createAccount
create_account_match = re.search(r'(Future<void> _createAccount\(\) async \{.*?final confirmPassword = confirmPasswordController\.text;)(.*?)(    setState\(\(\) => isLoading = true\);)', code, re.DOTALL)
if create_account_match:
    new_create_account = create_account_match.group(1) + '\n\n' + create_account_match.group(3)
    code = code[:create_account_match.start()] + new_create_account + code[create_account_match.end():]

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

# 5. Extract Details Block and Create Account button
details_regex = r'(// ── Details ──\s+FadeSlideIn\(\s+key: const ValueKey\(\'details\'\),.*?)(                            const SizedBox\(height: 20\),\s+SizedBox\(\s+width: double\.infinity,\s+child: PrimaryGlowButton\(.*?\),\s+\),\s+\),\s+],\s+\),\s+\),\s+\),\n)'
details_match = re.search(details_regex, code, re.DOTALL)
if details_match:
    details_top = details_match.group(1)
    create_btn_block = details_match.group(2)
    
    code = code[:details_match.start()] + code[details_match.end():]
    
    details_top = details_top.replace('index: 7', 'index: 0')
    
    continue_btn = '''                            if (!_accountDetailsValidated) ...[
                              const SizedBox(height: 20),
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
    new_details_block = details_top + continue_btn
    
    header_regex = r'(FadeSlideIn\(\s+key: const ValueKey\(\'header\'\),.*?const SizedBox\(height: 32\),\s+],\s+\),\s+\),\n)'
    header_match = re.search(header_regex, code, re.DOTALL)
    if header_match:
        insert_pos = header_match.end()
        code = code[:insert_pos] + new_details_block + code[insert_pos:]
        
        class_sel_pos = code.find('// ── Class selector ──')
        if class_sel_pos != -1:
            code = code[:class_sel_pos] + 'if (_accountDetailsValidated) ...[\n                    ' + code[class_sel_pos:]
            
            login_opt_pos = code.find("FadeSlideIn(\n                      key: const ValueKey('login_options'),")
            
            final_submit_block = '''
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
                                : Text(tr('create_account_btn')),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ], // end of if (_accountDetailsValidated)
'''
            code = code[:login_opt_pos] + final_submit_block + code[login_opt_pos:]
            
with open('lib/screens/register_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Done")
