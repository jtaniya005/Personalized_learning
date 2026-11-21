import 'package:flutter/material.dart';
import '../controllers/voice_assistant_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_mic_button.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/glass_card.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/waveform_visualizer.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final VoiceAssistantController controller;

  const VoiceAssistantScreen({
    super.key,
    required this.controller,
  });

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
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.recordingRed),
            SizedBox(width: 10),
            Text('Clear Conversation?'),
          ],
        ),
        content: const Text(
          'This will clear your conversation history on the server and reset the current chat.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.recordingRed,
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
      builder: (_) => SettingsDialog(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.purpleCyanGradient,
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
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Server status pill
          Center(
            child: ConnectionStatusBadge(
              status: controller.serverStatus,
              statusMessage: controller.serverStatusMessage,
              onTap: _openSettings,
            ),
          ),
          const SizedBox(width: 4),

          // Clear history button (calls /api/reset)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: 'Clear History',
            color: AppColors.textSecondary,
            onPressed: controller.messages.isEmpty ? null : _showClearHistoryDialog,
          ),

          // Settings button (Base URL / Config)
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            color: AppColors.textSecondary,
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient gradient mesh
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.ambientRadial,
              ),
            ),
          ),

          // Main Screen Content
          SafeArea(
            child: Column(
              children: [
                // Error banner (if any)
                if (controller.lastError != null)
                  _buildErrorBanner(controller.lastError!),

                // Conversation Log or Welcome View
                Expanded(
                  child: controller.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(),
                ),

                // Active speaking indicator / Floating "Stop Speaking" Button
                if (controller.isSpeaking) ...[
                  _buildStopSpeakingPill(),
                  const SizedBox(height: 8),
                ],

                // Central Action Area (Mic Button & State Label)
                _buildVoiceControlCenter(),

                // Bottom Fallback Text Bar
                _buildBottomInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusOffline.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusOffline.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.statusOffline, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: AppColors.statusOffline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.statusOffline),
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
                    AppColors.primaryIndigo.withOpacity(0.3),
                    AppColors.primaryPurple.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: AppColors.glassBorderHighlight, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 38,
                  color: AppColors.primaryCyan,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'How can I help you today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the microphone to speak or type a message below.\nResponses are powered by your FastAPI backend.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Quick suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((prompt) {
                return ActionChip(
                  backgroundColor: AppColors.glassWhite,
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  label: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
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
        return ChatBubble(
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
        backgroundColor: AppColors.recordingRed.withOpacity(0.18),
        border: Border.all(color: AppColors.recordingRed.withOpacity(0.5)),
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
                color: AppColors.recordingRed,
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
                  color: AppColors.recordingRed,
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
        stateColor = AppColors.recordingRed;
        break;
      case AssistantState.thinking:
        stateDescription = 'Thinking & processing response...';
        stateColor = AppColors.primaryCyan;
        break;
      case AssistantState.speaking:
        stateDescription = 'Speaking...';
        stateColor = AppColors.primaryIndigo;
        break;
      case AssistantState.idle:
      default:
        stateDescription = 'Tap to speak';
        stateColor = AppColors.textSecondary;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing Microphone centerpiece with state animations
        AnimatedMicButton(
          state: controller.state,
          amplitude: controller.currentAmplitude,
          onTap: controller.toggleListening,
        ),

        // Dynamic State text / waveform
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
        backgroundColor: AppColors.bgSurface.withOpacity(0.85),
        border: Border.all(color: AppColors.glassBorder),
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
              icon: const Icon(Icons.send_rounded, color: AppColors.primaryCyan, size: 20),
              tooltip: 'Send text',
              onPressed: _handleSendText,
            ),
          ],
        ),
      ),
    );
  }
}
