import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mock_data.dart';
import '../services/voice_assistant_service.dart';
import '../services/auth_service.dart';
import '../widgets/theme_decorations.dart';
import '../widgets/voice_assistant_modal.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  bool isTyping = false;
  bool _isSpeaking = false;
  int? _activePlayingIndex;
  String studentName = 'Student';

  final List<ChatMessage> messages = [];

  final List<Map<String, dynamic>> promptCards = [
    {
      'title': 'Explain a concept',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFEA580C),
      'prompt': 'Can you explain the most important concept in simple words with real-life examples?',
    },
    {
      'title': 'Solve a question',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFF59E0B),
      'prompt': 'Help me solve this difficult question step-by-step with clear reasoning.',
    },
    {
      'title': 'Career guidance',
      'icon': Icons.school_rounded,
      'color': const Color(0xFFEA580C),
      'prompt': 'What are the best career options, entrance exams, and college pathways based on my stream and marks?',
    },
    {
      'title': 'Make study plan',
      'icon': Icons.calendar_today_rounded,
      'color': const Color(0xFFF59E0B),
      'prompt': 'Create a high-impact daily revision study timetable for my upcoming board exams.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initVoiceService();
  }

  void _loadUserName() {
    final user = AuthService.currentUser;
    if (user != null && user['name'] != null && (user['name'] as String).isNotEmpty) {
      setState(() => studentName = user['name'].toString().split(' ').first);
    }
  }

  Future<void> _initVoiceService() async {
    await _voiceService.init();
    _voiceService.speakingStream.listen((speaking) {
      if (mounted) {
        setState(() {
          _isSpeaking = speaking;
          if (!speaking) {
            _activePlayingIndex = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _voiceService.dispose();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _send(String text, {bool isVoice = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (_isSpeaking) {
      await _voiceService.stopSpeaking();
    }

    setState(() {
      messages.add(ChatMessage(trimmed, true, isVoice: isVoice));
      controller.clear();
      isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _voiceService.sendTextMessage(trimmed);
      if (!mounted) return;

      final botMessage = ChatMessage(
        response.reply,
        false,
        audioBase64: response.audioBase64,
        ttsProvider: response.ttsProvider,
        careerGrounded: response.careerGrounded,
      );

      setState(() {
        isTyping = false;
        messages.add(botMessage);
      });
      _scrollToBottom();

      // Automatically play voice audio if available
      if (response.audioBase64 != null && response.audioBase64!.isNotEmpty) {
        setState(() => _activePlayingIndex = messages.length - 1);
        await _voiceService.playVoiceResponse(response);
      }
    } catch (e) {
      debugPrint('[AiChatScreen] Error communicating with Buddy AI: $e');
      if (!mounted) return;
      setState(() {
        isTyping = false;
        messages.add(ChatMessage(
          "Arre waah $studentName! Maine aapka doubt (\"$trimmed\") note kar liya hai. Abhi backend se connect karne me problem aayi ($e). Kripya check karein ki FastAPI backend '${_voiceService.baseUrl}' par live run ho raha hai.",
          false,
        ));
      });
      _scrollToBottom();
    }
  }

  void _togglePlayMessageAudio(int index, ChatMessage msg) async {
    if (_activePlayingIndex == index && _isSpeaking) {
      await _voiceService.stopSpeaking();
      setState(() => _activePlayingIndex = null);
      return;
    }

    setState(() => _activePlayingIndex = index);

    final vResp = VoiceResponse(
      question: '',
      reply: msg.text,
      audioBase64: msg.audioBase64,
      ttsProvider: msg.ttsProvider ?? 'edge_tts',
    );
    await _voiceService.playVoiceResponse(vResp);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 140,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _openVoiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceAssistantModal(
        voiceService: _voiceService,
        onInteractionComplete: (userText, assistantReply) {
          if (mounted && userText.isNotEmpty) {
            setState(() {
              messages.add(ChatMessage(userText, true, isVoice: true));
              messages.add(ChatMessage(
                assistantReply,
                false,
                careerGrounded: userText.toLowerCase().contains('career') ||
                    userText.toLowerCase().contains('job') ||
                    userText.toLowerCase().contains('course'),
              ));
            });
            _scrollToBottom();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar: Back Arrow, AI Doubt Assistant, Sparkles ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E1B18)),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFEA580C)),
                            const SizedBox(width: 4),
                            Text(
                              'Gemini 2.5 Flash',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('✨', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Screen Header Title & Subtitle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Doubt Assistant',
                      style: GoogleFonts.fraunces(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B18),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ask anything, get instant help!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B655B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Main Content Area (Mascot, Prompt Cards & Chat Messages) ──
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Mascot Speech Bubble Banner (Screen 9)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const BuddyMascotWidget(size: 76),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8DECF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.025),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi $studentName! 👋',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1B18),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'What would you like to learn today?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF524C42),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4 Quick Prompt Cards (Screen 9)
                  if (messages.isEmpty) ...[
                    ...promptCards.map((item) {
                      return GestureDetector(
                        onTap: () => _send(item['prompt'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8DECF)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8ED),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1B18),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFA8A29E)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // Chat Message Bubbles
                  ...messages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final msg = entry.value;

                    if (msg.isUser) {
                      return _buildUserBubble(msg);
                    } else {
                      return _buildBuddyBubble(index, msg);
                    }
                  }),

                  if (isTyping) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8DECF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Buddy is answering with Gemini 2.5 Flash...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF78716C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Quick Chips when messages exist ──
            if (messages.isNotEmpty)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: promptCards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final item = promptCards[i];
                    return GestureDetector(
                      onTap: () => _send(item['prompt'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8DECF)),
                        ),
                        child: Row(
                          children: [
                            Icon(item['icon'] as IconData, size: 14, color: item['color'] as Color),
                            const SizedBox(width: 6),
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1B18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── Bottom Input Bar: Textfield, Microphone, Orange Circular Button (Screen 9) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 54,
                padding: const EdgeInsets.only(left: 18, right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFFE8DECF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onSubmitted: (txt) => _send(txt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF1E1B18),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFFA8A29E),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    // Microphone Icon -> launches Voice Assistant Modal (Voice AI Mentor)
                    IconButton(
                      icon: const Icon(Icons.mic_rounded, color: Color(0xFFEA580C), size: 23),
                      tooltip: 'Voice AI Mentor',
                      onPressed: _openVoiceModal,
                    ),
                    // Circular Orange Send Button
                    GestureDetector(
                      onTap: () => _send(controller.text),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 21),
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

  // ── User Message Bubble ──
  Widget _buildUserBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withOpacity(0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.isVoice)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Voice Question',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Buddy Assistant Message Bubble ──
  Widget _buildBuddyBubble(int index, ChatMessage msg) {
    final isPlaying = _activePlayingIndex == index && _isSpeaking;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 28),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: const Color(0xFFE8DECF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar + Name + Grounded Badge + Copy
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.smart_toy_outlined, size: 16, color: Color(0xFFEA580C)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Buddy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B18),
                  ),
                ),
                const SizedBox(width: 8),
                if (msg.careerGrounded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore_outlined, size: 11, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          'Pinecone Career DB',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Copy text button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFA8A29E)),
                  tooltip: 'Copy reply',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Formatted Message Text
            _buildFormattedText(msg.text),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF5EFE6)),
            const SizedBox(height: 8),

            // Bottom Audio Control Bar
            Row(
              children: [
                GestureDetector(
                  onTap: () => _togglePlayMessageAudio(index, msg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPlaying ? const Color(0xFFFEF2F2) : const Color(0xFFFFF8ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPlaying ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                          size: 15,
                          color: isPlaying ? const Color(0xFFDC2626) : const Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPlaying ? 'Stop Voice' : 'Listen Voice',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isPlaying ? const Color(0xFFDC2626) : const Color(0xFFEA580C),
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Edge-TTS Neural Voice',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFFA8A29E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper to render clean structured paragraphs, bullet points, and bold styling ──
  Widget _buildFormattedText(String content) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 6);

        // Check for bullet lines
        final isBullet = trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*');
        final displayText = isBullet ? trimmed.replaceFirst(RegExp(r'^[•\-\*]\s*'), '') : trimmed;

        return Padding(
          padding: EdgeInsets.only(bottom: isBullet ? 4 : 5, left: isBullet ? 6 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet)
                const Padding(
                  padding: EdgeInsets.only(top: 5, right: 6),
                  child: Icon(Icons.circle, size: 5, color: Color(0xFFEA580C)),
                ),
              Expanded(
                child: Text(
                  displayText.replaceAll('**', ''),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: (trimmed.startsWith('#') || trimmed.contains('**') && trimmed.length < 50)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: const Color(0xFF26231F),
                    height: 1.42,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
