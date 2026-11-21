import 'package:flutter/material.dart';
import '../controllers/voice_assistant_controller.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
 
class SettingsDialog extends StatefulWidget {
  final VoiceAssistantController controller;

  const SettingsDialog({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;
  bool _testingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.controller.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });

    final targetUrl = _urlController.text.trim();
    await widget.controller.updateBaseUrl(targetUrl);

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _testSuccess =
            widget.controller.serverStatus == ServerStatus.online;
        _testResult = widget.controller.serverStatusMessage;
      });
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _urlController.text = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        blur: 24,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        backgroundColor: AppColors.bgSurface.withOpacity(0.92),
        border: Border.all(color: AppColors.glassBorderHighlight.withOpacity(0.4)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppColors.primaryCyan, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Backend Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Server URL label
              const Text(
                'FastAPI Base URL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Text Field
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primaryIndigo),
                  hintText: 'http://10.0.2.2:8000',
                  suffixIcon: IconButton(
                    icon: _testingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppColors.primaryCyan),
                    tooltip: 'Test Connection',
                    onPressed: _testingConnection ? null : _testConnection,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Presets
              const Text(
                'Quick Presets:',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPresetChip('Android (10.0.2.2)', 'http://10.0.2.2:8000'),
                  _buildPresetChip('iOS / PC (localhost)', 'http://localhost:8000'),
                  _buildPresetChip('LAN (192.168.1.100)', 'http://192.168.1.100:8000'),
                ],
              ),

              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? AppColors.statusOnline.withOpacity(0.12)
                        : AppColors.statusOffline.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _testSuccess
                          ? AppColors.statusOnline.withOpacity(0.4)
                          : AppColors.statusOffline.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        color: _testSuccess
                            ? AppColors.statusOnline
                            : AppColors.statusOffline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testSuccess
                                ? AppColors.statusOnline
                                : AppColors.statusOffline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(color: AppColors.glassBorder, height: 28),

              // Session ID
              const Text(
                'Session ID (Persistent X-Session-ID)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.controller.sessionId,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.accentNeon,
                ),
              ),

              const SizedBox(height: 16),

              // Audio / Speech Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voice Response (TTS)',
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  Switch(
                    value: widget.controller.ttsEnabled,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (val) {
                      widget.controller.setTtsEnabled(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await widget.controller.updateBaseUrl(_urlController.text);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Save & Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
      backgroundColor: AppColors.glassWhite,
      side: const BorderSide(color: AppColors.glassBorder),
      onPressed: () => _applyPreset(url),
    );
  }
}
