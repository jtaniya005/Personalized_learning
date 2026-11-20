import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/voice_chat_message.dart';
import '../theme/voice_app_theme.dart';
import 'glass_card.dart';

class VoiceChatBubble extends StatelessWidget {
  final VoiceChatMessage message;
  final VoidCallback? onReplay;

  const VoiceChatBubble({
    super.key,
    required this.message,
    this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage(context);
    }
    return message.isUser ? _buildUserBubble(context) : _buildAssistantBubble(context);
  }

  Widget _buildSystemMessage(BuildContext context) {
    final isError = message.status == MessageStatus.error;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isError
            ? VoiceAppColors.statusOffline.withOpacity(0.12)
            : VoiceAppColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? VoiceAppColors.statusOffline.withOpacity(0.3)
              : VoiceAppColors.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 16,
            color: isError ? VoiceAppColors.statusOffline : VoiceAppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isError ? VoiceAppColors.statusOffline : VoiceAppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              gradient: VoiceAppColors.indigoPurpleGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: VoiceAppColors.primaryIndigo.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.isVoice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          size: 14,
                          color: VoiceAppColors.accentNeon.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voice Query',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VoiceAppColors.accentNeon.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                SelectableText(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    if (message.status == MessageStatus.sending) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: VoiceAppColors.purpleCyanGradient,
                  boxShadow: [
                    BoxShadow(
                      color: VoiceAppColors.primaryCyan.withOpacity(0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: GlassCard(
                  padding: const EdgeInsets.all(14.0),
                  borderRadius: 18.0,
                  backgroundColor: VoiceAppColors.bgSurface.withOpacity(0.65),
                  border: Border.all(
                    color: VoiceAppColors.glassBorderHighlight.withOpacity(0.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: VoiceAppColors.primaryIndigo.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: VoiceAppColors.primaryIndigo.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              message.ttsProvider == 'orpheus'
                                  ? 'Orpheus Server Voice'
                                  : 'AI Assistant',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VoiceAppColors.accentNeon,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                visualDensity: VisualDensity.compact,
                                color: VoiceAppColors.textSecondary,
                                tooltip: 'Copy to clipboard',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: message.text),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to clipboard'),
                                      duration: Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              if (onReplay != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.volume_up_rounded,
                                    size: 15,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  color: VoiceAppColors.primaryCyan,
                                  tooltip: 'Replay audio',
                                  onPressed: onReplay,
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        message.text,
                        style: const TextStyle(
                          color: VoiceAppColors.textPrimary,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: VoiceAppColors.textMuted.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
