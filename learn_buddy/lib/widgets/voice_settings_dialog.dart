import 'package:flutter/material.dart';
import '../controllers/voice_assistant_controller.dart';
import '../theme/voice_app_theme.dart';
import '../config/api_config.dart';
import 'glass_card.dart';

class VoiceSettingsDialog extends StatefulWidget {
  final VoiceAssistantController controller;

  const VoiceSettingsDialog({
    super.key,
    required this.controller,
  });

  @override
  State<VoiceSettingsDialog> createState() => _VoiceSettingsDialogState();
}

class _VoiceSettingsDialogState extends State<VoiceSettingsDialog> {
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
        backgroundColor: VoiceAppColors.bgSurface.withOpacity(0.92),
        border: Border.all(color: VoiceAppColors.glassBorderHighlight.withOpacity(0.4)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: VoiceAppColors.primaryCyan, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Backend Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: VoiceAppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: VoiceAppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'FastAPI Base URL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VoiceAppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link_rounded, color: VoiceAppColors.primaryIndigo),
                  hintText: 'http://10.0.2.2:8000',
                  suffixIcon: IconButton(
                    icon: _testingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, color: VoiceAppColors.primaryCyan),
                    tooltip: 'Test Connection',
                    onPressed: _testingConnection ? null : _testConnection,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick Presets:',
                style: TextStyle(fontSize: 12, color: VoiceAppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPresetChip('Cloud AI (cleariq.freekey.ai:9009)', 'https://cleariq.freekey.ai:9009'),
                  _buildPresetChip('Local Docker (Port 2500)', ApiConfig.getLocalBaseUrl(port: 2500)),
                  _buildPresetChip('PC Local (localhost:2500)', 'http://localhost:2500'),
                  _buildPresetChip('Android (10.0.2.2:2500)', 'http://10.0.2.2:2500'),
                  _buildPresetChip('Local Dev (Port 8000)', 'http://localhost:8000'),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? VoiceAppColors.statusOnline.withOpacity(0.12)
                        : VoiceAppColors.statusOffline.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _testSuccess
                          ? VoiceAppColors.statusOnline.withOpacity(0.4)
                          : VoiceAppColors.statusOffline.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        color: _testSuccess
                            ? VoiceAppColors.statusOnline
                            : VoiceAppColors.statusOffline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testSuccess
                                ? VoiceAppColors.statusOnline
                                : VoiceAppColors.statusOffline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(color: VoiceAppColors.glassBorder, height: 28),
              const Text(
                'Session ID (Persistent X-Session-ID)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VoiceAppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.controller.sessionId,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: VoiceAppColors.accentNeon,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voice Response (TTS)',
                    style: TextStyle(fontSize: 14, color: VoiceAppColors.textPrimary),
                  ),
                  Switch(
                    value: widget.controller.ttsEnabled,
                    activeColor: VoiceAppColors.primaryCyan,
                    onChanged: (val) {
                      widget.controller.setTtsEnabled(val);
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: VoiceAppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VoiceAppColors.primaryIndigo,
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
      label: Text(label, style: const TextStyle(fontSize: 11, color: VoiceAppColors.textPrimary)),
      backgroundColor: VoiceAppColors.glassWhite,
      side: const BorderSide(color: VoiceAppColors.glassBorder),
      onPressed: () => _applyPreset(url),
    );
  }
}
