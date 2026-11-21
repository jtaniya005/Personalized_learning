import 'package:flutter/material.dart';
import '../controllers/voice_assistant_controller.dart';
import '../theme/voice_app_theme.dart';
import '../widgets/animated_mic_button.dart';
import '../widgets/voice_chat_bubble.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/glass_card.dart';
import '../widgets/voice_settings_dialog.dart';
import '../widgets/waveform_visualizer.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final VoiceAssistantController controller;

  const VoiceAssistantScreen({
    super.key,
    required this.controller,
  });

  /// Helper factory to automatically instantiate services & controller
  static Widget withNewController() {
    return FutureBuilder<VoiceAssistantController>(
      future: VoiceAssistantController.create(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: VoiceAppColors.bgPrimary,
            body: const Center(
              child: CircularProgressIndicator(color: VoiceAppColors.primaryIndigo),
            ),
          );
        }
        return VoiceAssistantScreen(controller: snapshot.data!);
      },
    );
  }

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _quickPrompts = const [
    'What can you help me with?',
    'Summarize my study schedule',
    'Explain Newton\'s laws of motion',
    'Motivate me for my exam',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();
    widget.controller.sendTextMessage(text);
  }

  Future<void> _showClearHistoryDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VoiceAppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VoiceAppColors.glassBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: VoiceAppColors.recordingRed),
            SizedBox(width: 10),
            Text('Clear Conversation?'),
          ],
        ),
        content: const Text(
          'This will clear your conversation history on the server and reset the current chat.',
          style: TextStyle(color: VoiceAppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: VoiceAppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VoiceAppColors.recordingRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.clearHistory();
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) => VoiceSettingsDialog(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Theme(
      data: VoiceAppTheme.darkTheme,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: VoiceAppColors.purpleCyanGradient,
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Voice Assistant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: VoiceAppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ConnectionStatusBadge(
                status: controller.serverStatus,
                statusMessage: controller.serverStatusMessage,
                onTap: _openSettings,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Clear History',
              color: VoiceAppColors.textSecondary,
              onPressed: controller.messages.isEmpty ? null : _showClearHistoryDialog,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Settings',
              color: VoiceAppColors.textSecondary,
              onPressed: _openSettings,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: VoiceAppColors.ambientRadial,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  if (controller.lastError != null)
                    _buildErrorBanner(controller.lastError!),
                  Expanded(
                    child: controller.messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(),
                  ),
                  if (controller.isSpeaking) ...[
                    _buildStopSpeakingPill(),
                    const SizedBox(height: 8),
                  ],
                  _buildVoiceControlCenter(),
                  _buildBottomInputBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VoiceAppColors.statusOffline.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VoiceAppColors.statusOffline.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: VoiceAppColors.statusOffline, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: VoiceAppColors.statusOffline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: VoiceAppColors.statusOffline),
            visualDensity: VisualDensity.compact,
            onPressed: widget.controller.dismissError,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    VoiceAppColors.primaryIndigo.withOpacity(0.3),
                    VoiceAppColors.primaryPurple.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: VoiceAppColors.glassBorderHighlight, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 38,
                  color: VoiceAppColors.primaryCyan,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'How can I help you today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VoiceAppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the microphone to speak or type a message below.\nResponses are powered by your FastAPI backend.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: VoiceAppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((prompt) {
                return ActionChip(
                  backgroundColor: VoiceAppColors.glassWhite,
                  side: const BorderSide(color: VoiceAppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  label: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: VoiceAppColors.textPrimary,
                    ),
                  ),
                  onPressed: () => widget.controller.sendTextMessage(prompt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: widget.controller.messages.length,
      itemBuilder: (context, index) {
        final msg = widget.controller.messages[index];
        return VoiceChatBubble(
          message: msg,
          onReplay: msg.isAssistant
              ? () {
                  widget.controller.playbackService.playReply(
                    text: msg.text,
                    audioBase64: msg.audioBase64,
                    ttsProvider: msg.ttsProvider,
                  );
                }
              : null,
        );
      },
    );
  }

  Widget _buildStopSpeakingPill() {
    return Center(
      child: GlassCard(
        blur: 16,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        backgroundColor: VoiceAppColors.recordingRed.withOpacity(0.18),
        border: Border.all(color: VoiceAppColors.recordingRed.withOpacity(0.5)),
        child: InkWell(
          onTap: widget.controller.stopSpeaking,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WaveformVisualizer(
                isPlaying: true,
                barCount: 6,
                height: 18,
                color: VoiceAppColors.recordingRed,
              ),
              const SizedBox(width: 10),
              const Text(
                'Stop Speaking',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VoiceAppColors.recordingRed,
                ),
                child: const Icon(Icons.stop_rounded, size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceControlCenter() {
    final controller = widget.controller;

    String stateDescription;
    Color stateColor;

    switch (controller.state) {
      case AssistantState.listening:
        stateDescription = 'Listening... Tap again to send';
        stateColor = VoiceAppColors.recordingRed;
        break;
      case AssistantState.thinking:
        stateDescription = 'Thinking & processing response...';
        stateColor = VoiceAppColors.primaryCyan;
        break;
      case AssistantState.speaking:
        stateDescription = 'Speaking...';
        stateColor = VoiceAppColors.primaryIndigo;
        break;
      case AssistantState.idle:
      default:
        stateDescription = 'Tap to speak';
        stateColor = VoiceAppColors.textSecondary;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedMicButton(
          state: controller.state,
          amplitude: controller.currentAmplitude,
          onTap: controller.toggleListening,
        ),
        if (controller.isSpeaking)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: WaveformVisualizer(
              isPlaying: true,
              barCount: 24,
              height: 28,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              stateDescription,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: stateColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GlassCard(
        blur: 16,
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        backgroundColor: VoiceAppColors.bgSurface.withOpacity(0.85),
        border: Border.all(color: VoiceAppColors.glassBorder),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask or type fallback query...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendText(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: VoiceAppColors.primaryCyan, size: 20),
              tooltip: 'Send text',
              onPressed: _handleSendText,
            ),
          ],
        ),
      ),
    );
  }
}
