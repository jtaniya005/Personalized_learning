import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../services/voice_assistant_service.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/notebook_card.dart';
import '../widgets/voice_assistant_modal.dart';
import 'voice_assistant_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

/// Steps of Buddy's proactive opening sequence — the mentor speaks
/// first, instead of waiting for the student to ask something.
enum _IntroStep { none, typingFirst, firstShown, typingCheckIn, checkInShown }

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  bool isTyping = false;
  _IntroStep intro = _IntroStep.none;
  String chatLanguage = 'English';
  bool _isSpeaking = false;
  bool _isRecording = false;
  bool _isBackendConnected = false;

  final List<ChatMessage> messages = [];

  final List<String> suggestions = const [
    "What's today's plan?",
    'Motivate me',
    "What's my weak area?",
    'Am I exam-ready?',
  ];

  @override
  void initState() {
    super.initState();
    _initVoiceService();
    _runIntroSequence();
  }

  Future<void> _initVoiceService() async {
    await _voiceService.init();

    _voiceService.speakingStream.listen((speaking) {
      if (mounted) setState(() => _isSpeaking = speaking);
    });

    final online = await _voiceService.checkHealth();
    if (mounted) setState(() => _isBackendConnected = online);
  }

  @override
  void dispose() {
    _voiceService.dispose();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleMicRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        isTyping = true;
      });
      _scrollToBottom();

      try {
        final response = await _voiceService.stopRecordingAndSend();
        if (response != null && mounted) {
          setState(() {
            isTyping = false;
            messages.add(ChatMessage(
              response.question.isNotEmpty ? response.question : '[Voice Question]',
              true,
              isVoice: true,
            ));
            messages.add(ChatMessage(
              response.reply,
              false,
              audioBase64: response.audioBase64,
              ttsProvider: response.ttsProvider,
            ));
          });
          _scrollToBottom();
          await _voiceService.playVoiceResponse(response);
        } else if (mounted) {
          setState(() => isTyping = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isTyping = false;
            messages.add(const ChatMessage(
              "Sorry, I had trouble processing your voice audio with the server. Please check your backend connection.",
              false,
            ));
          });
          _scrollToBottom();
        }
      }
    } else {
      final started = await _voiceService.startRecording();
      if (started && mounted) {
        setState(() => _isRecording = true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable microphone access in settings.')),
        );
      }
    }
  }

  Future<void> _runIntroSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => intro = _IntroStep.typingFirst);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => intro = _IntroStep.firstShown);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => intro = _IntroStep.typingCheckIn);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => intro = _IntroStep.checkInShown);
    _scrollToBottom();
  }

  void _send(String text, {String? replyOverride}) async {
    if (_isRecording) await _voiceService.cancelRecording();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(trimmed, true));
      controller.clear();
      isTyping = true;
    });
    _scrollToBottom();

    if (replyOverride != null) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        isTyping = false;
        messages.add(ChatMessage(replyOverride, false));
      });
      _scrollToBottom();
      return;
    }

    try {
      // Call FastAPI backend POST /api/chat
      final response = await _voiceService.sendTextMessage(trimmed);
      if (!mounted) return;

      setState(() {
        isTyping = false;
        messages.add(ChatMessage(
          response.reply,
          false,
          audioBase64: response.audioBase64,
          ttsProvider: response.ttsProvider,
        ));
      });
      _scrollToBottom();

      // Speak assistant answer
      await _voiceService.playVoiceResponse(response);
    } catch (e) {
      // Fallback gracefully if server is unreachable
      if (!mounted) return;
      setState(() {
        isTyping = false;
        messages.add(ChatMessage(
          "I received: \"$trimmed\". (Backend offline at ${_voiceService.baseUrl}. Tap the settings icon to adjust host IP).",
          false,
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 140,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _openVoiceAssistantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceAssistantModal(
        voiceService: _voiceService,
        onInteractionComplete: (userText, assistantReply) {
          if (mounted) {
            setState(() {
              messages.add(ChatMessage(userText, true, isVoice: true));
              messages.add(ChatMessage(assistantReply, false));
            });
            _scrollToBottom();
          }
        },
      ),
    );
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text(
          'This will reset your conversation history on the FastAPI backend and clear current messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _voiceService.resetSession();
      setState(() {
        messages.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation history cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
          child: Row(
            children: [
              _BreathingAvatar(messageCount: messages.length),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Buddy', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isBackendConnected
                                ? AppColors.sage.withOpacity(0.18)
                                : AppColors.rule.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isBackendConnected ? 'FastAPI Online' : 'FastAPI Offline',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _isBackendConnected ? AppColors.sage : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _isBackendConnected ? AppColors.sage : AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tr(context, 'buddy_mentor'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Voice Assistant Launcher Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VoiceAssistantScreen.withNewController(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Voice Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Clear chat button
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.inkSoft),
                tooltip: 'Clear Chat',
                onPressed: messages.isEmpty ? null : _clearChatHistory,
              ),

              // Chat language switch
              PopupMenuButton<String>(
                initialValue: chatLanguage,
                onSelected: (v) => setState(() => chatLanguage = v),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate_rounded, size: 18, color: AppColors.inkSoft),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.inkSoft),
                  ],
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'English', child: Text('English')),
                  PopupMenuItem(value: 'Hindi', child: Text('हिंदी')),
                  PopupMenuItem(value: 'Hinglish', child: Text('Hinglish')),
                ],
              ),
            ],
          ),
        ),
        Divider(color: AppColors.rule, height: 1),

        // ── Messages ──
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            children: [
              // Buddy's opening observation
              if (intro == _IntroStep.typingFirst) const _TypingBubble(),
              if (intro.index >= _IntroStep.firstShown.index)
                const _Bubble(
                  message: ChatMessage(
                    "Hey! I noticed you left Trigonometry half-done "
                    "yesterday, and Science has been skipped for 3 days. "
                    "Everything okay? 🙂",
                    false,
                  ),
                ),
              if (intro == _IntroStep.typingCheckIn) const _TypingBubble(),
              if (intro.index >= _IntroStep.checkInShown.index)
                _CheckInCard(
                  onAccept: () => _send(
                    "Yes, let's start with Trigonometry",
                    replyOverride:
                        "Great! We'll revise the basic identities first, "
                        "then go straight into practice. Ready when you are.",
                  ),
                  onLater: () => _send(
                    "I'll do it a bit later",
                    replyOverride:
                        "No rush at all. Whenever you're ready, just say "
                        "the word — I'll be here. 🙂",
                  ),
                ),

              // Back-and-forth messages
              ...messages.map(
                (m) => _Bubble(
                  message: m,
                  onReplay: !m.isUser
                      ? () => _voiceService.playVoiceResponse(
                            VoiceResponse(
                              question: '',
                              reply: m.text,
                              audioBase64: m.audioBase64,
                              ttsProvider: m.ttsProvider ?? 'browser',
                            ),
                          )
                      : null,
                ),
              ),
              if (isTyping) const _TypingBubble(),
            ],
          ),
        ),

        // ── Floating Stop Speaking Button ──
        if (_isSpeaking)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.stop_rounded, size: 16),
              label: const Text('Stop Speaking', style: TextStyle(fontSize: 12)),
              onPressed: () => _voiceService.stopSpeaking(),
            ),
          ),

        // ── Suggestion chips ──
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _send(suggestions[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paperCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Text(
                  suggestions[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Recording indicator ──
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0, left: 24.0),
            child: Row(
              children: const [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                ),
                SizedBox(width: 8),
                Text(
                  'Listening... Tap mic again to send to FastAPI',
                  style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),

        // ── Bottom Input bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: tr(context, 'chat_input_hint'),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Mic Button for Direct Voice Query (POST /api/ask)
              GestureDetector(
                onTap: _toggleMicRecording,
                onLongPress: _openVoiceAssistantModal,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.coral.withOpacity(0.18) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? AppColors.coral : AppColors.rule,
                      width: _isRecording ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: _isRecording ? AppColors.coral : AppColors.inkSoft,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Text Button (POST /api/chat)
              GestureDetector(
                onTap: () => _send(controller.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.ink, const Color(0xFF34424C)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_upward_rounded, color: AppColors.paper),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mentor's structured check-in card
class _CheckInCard extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onLater;

  const _CheckInCard({required this.onAccept, required this.onLater});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: NotebookCard(
        holeCount: 4,
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, size: 16, color: AppColors.coral),
                const SizedBox(width: 6),
                Text(tr(context, 'todays_plan_card'), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 10),
            Text('Trigonometry — revise the basics?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('~30 min · worth 8-10 marks most years', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.marigold,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(tr(context, 'lets_start')),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onLater,
                  child: Text(tr(context, 'later'), style: TextStyle(color: AppColors.inkSoft)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Buddy's avatar gently "breathes"
class _BreathingAvatar extends StatefulWidget {
  final int messageCount;
  const _BreathingAvatar({required this.messageCount});

  @override
  State<_BreathingAvatar> createState() => _BreathingAvatarState();
}

class _BreathingAvatarState extends State<_BreathingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.scale(
        scale: 0.94 + 0.08 * controller.value,
        child: child,
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.marigold.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '🦉',
            style: TextStyle(
              fontSize: 22,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chat Bubble with voice query tag and speech replay support
class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onReplay;

  const _Bubble({required this.message, this.onReplay});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? AppColors.ink : AppColors.paperCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: AppColors.rule),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.isVoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 12, color: AppColors.paper.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        'Voice Query',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.paper.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(
                  color: isUser ? AppColors.paper : AppColors.ink,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              if (!isUser && onReplay != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: GestureDetector(
                    onTap: onReplay,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, size: 14, color: AppColors.inkSoft),
                        const SizedBox(width: 4),
                        Text(
                          'Listen again',
                          style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
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

/// Three bouncing dots shown while Buddy is "typing" a reply
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paperCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.rule),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (controller.value - i * 0.2) % 1.0;
                final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * bounce,
                    child: Opacity(
                      opacity: 0.3 + 0.7 * bounce,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.inkSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
