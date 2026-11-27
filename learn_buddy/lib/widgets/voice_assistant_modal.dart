import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_assistant_service.dart';

enum AssistantState { idle, listening, thinking, speaking }

class VoiceAssistantModal extends StatefulWidget {
  final VoiceAssistantService voiceService;
  final Function(String userText, String assistantReply)? onInteractionComplete;

  const VoiceAssistantModal({
    super.key,
    required this.voiceService,
    this.onInteractionComplete,
  });

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with TickerProviderStateMixin {
  AssistantState _state = AssistantState.idle;
  String _statusText = 'Tap microphone to speak with Buddy';
  String _userSpeech = '';
  String _assistantReply = '';
  double _amplitude = 0.0;
  bool _isOnline = false;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _breatheController;

  final List<String> _quickVoicePrompts = const [
    'What are the top careers after Class 12 Science PCM?',
    'Explain the concept of Photosynthesis in simple words',
    'Best career options for Commerce without Maths',
    'Give me a 3-hour daily revision timetable for board exams',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    widget.voiceService.speakingStream.listen((isSpeaking) {
      if (!isSpeaking && _state == AssistantState.speaking) {
        if (mounted) {
          setState(() {
            _state = AssistantState.idle;
            _statusText = 'Tap microphone to speak again';
          });
        }
      }
    });

    widget.voiceService.amplitudeStream.listen((amp) {
      if (mounted && _state == AssistantState.listening) {
        setState(() => _amplitude = amp);
      }
    });

    _checkServer();
  }

  Future<void> _checkServer() async {
    final online = await widget.voiceService.checkHealth();
    if (mounted) setState(() => _isOnline = online);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_state == AssistantState.listening) {
      setState(() {
        _state = AssistantState.thinking;
        _statusText = 'Thinking with Gemini 2.5 Flash...';
      });

      try {
        final response = await widget.voiceService.stopRecordingAndSend();
        if (response != null && mounted) {
          setState(() {
            _userSpeech = response.question;
            _assistantReply = response.reply;
            _state = AssistantState.speaking;
            _statusText = 'Buddy is speaking...';
          });

          widget.onInteractionComplete?.call(response.question, response.reply);
          await widget.voiceService.playVoiceResponse(response);
        } else if (mounted) {
          setState(() {
            _state = AssistantState.idle;
            _statusText = 'No speech detected. Please tap again.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _state = AssistantState.idle;
            _statusText = 'Voice query processed. Tap to continue.';
          });
        }
      }
    } else if (_state == AssistantState.speaking) {
      await widget.voiceService.stopSpeaking();
      setState(() {
        _state = AssistantState.idle;
        _statusText = 'Voice stopped. Tap microphone to speak.';
      });
    } else if (_state == AssistantState.idle) {
      final started = await widget.voiceService.startRecording();
      if (started && mounted) {
        setState(() {
          _state = AssistantState.listening;
          _statusText = 'Listening... Tap again when finished';
          _userSpeech = '';
          _assistantReply = '';
        });
      }
    }
  }

  Future<void> _askQuickPrompt(String prompt) async {
    if (_state == AssistantState.listening) {
      await widget.voiceService.cancelRecording();
    }
    setState(() {
      _state = AssistantState.thinking;
      _userSpeech = prompt;
      _statusText = 'Thinking with Gemini 2.5 Flash...';
    });

    try {
      final response = await widget.voiceService.sendTextMessage(prompt);
      if (mounted) {
        setState(() {
          _assistantReply = response.reply;
          _state = AssistantState.speaking;
          _statusText = 'Buddy is speaking...';
        });

        widget.onInteractionComplete?.call(prompt, response.reply);
        await widget.voiceService.playVoiceResponse(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = AssistantState.idle;
          _statusText = 'Tap microphone to speak';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9), // Warm Editorial Cream
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6C8B8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),

            // Top Header: Title, Status Pill, Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.smart_toy_outlined, size: 18, color: Color(0xFFEA580C)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice AI Mentor',
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1B18),
                          ),
                        ),
                        Text(
                          'Gemini 2.5 Flash · Pinecone Grounded',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Transcription & Reply Card
            if (_userSpeech.isNotEmpty || _assistantReply.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                    if (_userSpeech.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.mic, size: 14, color: Color(0xFFEA580C)),
                          const SizedBox(width: 6),
                          Text(
                            'You asked:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFFEA580C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userSpeech,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1B18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF0E7DB)),
                      const SizedBox(height: 10),
                    ],
                    if (_assistantReply.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Text(
                            'Buddy replied (Voice AI):',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _assistantReply,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF44403C),
                          height: 1.4,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

            // Central Animated Pulsing Microphone Widget
            SizedBox(
              height: 140,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Concentric waves when LISTENING
                    if (_state == AssistantState.listening)
                      ...List.generate(3, (index) {
                        final wave = (_pulseController.value + (index / 3.0)) % 1.0;
                        final radius = 38.0 + (wave * 38.0) + (_amplitude * 16.0);
                        final opacity = (1.0 - wave).clamp(0.0, 0.6);
                        return Container(
                          width: radius * 2,
                          height: radius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEA580C).withOpacity(opacity),
                              width: 2.2,
                            ),
                          ),
                        );
                      }),

                    // Rotating gradient spinner when THINKING
                    if (_state == AssistantState.thinking)
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (_, __) => Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Container(
                            width: 92,
                            height: 92,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFF59E0B),
                                  Color(0xFFEA580C),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Breathing aura when IDLE or SPEAKING
                    if (_state == AssistantState.idle || _state == AssistantState.speaking)
                      AnimatedBuilder(
                        animation: _breatheController,
                        builder: (_, __) => Container(
                          width: 80 + (_breatheController.value * 10),
                          height: 80 + (_breatheController.value * 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                          ),
                        ),
                      ),

                    // Core Button
                    GestureDetector(
                      onTap: _toggleVoice,
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _state == AssistantState.listening
                                ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                                : _state == AssistantState.speaking
                                    ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                    : [const Color(0xFFF97316), const Color(0xFFEA580C)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEA580C).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _state == AssistantState.listening
                                ? Icons.stop_rounded
                                : _state == AssistantState.thinking
                                    ? Icons.hourglass_top_rounded
                                    : _state == AssistantState.speaking
                                        ? Icons.volume_up_rounded
                                        : Icons.mic_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Status message
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _state == AssistantState.listening
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF1E1B18),
              ),
            ),

            if (_state == AssistantState.speaking) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.stop_circle_outlined, size: 18, color: Color(0xFFDC2626)),
                label: Text(
                  'Stop Speaking',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                onPressed: () async {
                  await widget.voiceService.stopSpeaking();
                  setState(() {
                    _state = AssistantState.idle;
                    _statusText = 'Speech stopped. Tap microphone to speak.';
                  });
                },
              ),
            ],

            const SizedBox(height: 16),

            // Quick Voice Suggestion Prompts
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try asking verbally:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF78716C),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickVoicePrompts.map((p) {
                return GestureDetector(
                  onTap: () => _askQuickPrompt(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8DECF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFFEA580C)),
                        const SizedBox(width: 6),
                        Text(
                          p,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1B18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
