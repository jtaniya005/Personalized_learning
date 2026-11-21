import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  String _statusText = 'Tap microphone to speak';
  String _userSpeech = '';
  String _assistantReply = '';
  double _amplitude = 0.0;
  bool _isOnline = false;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    widget.voiceService.speakingStream.listen((isSpeaking) {
      if (!isSpeaking && _state == AssistantState.speaking) {
        if (mounted) {
          setState(() {
            _state = AssistantState.idle;
            _statusText = 'Tap to speak again';
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
        _statusText = 'Transcribing and thinking...';
      });

      try {
        final response = await widget.voiceService.stopRecordingAndSend();
        if (response != null && mounted) {
          setState(() {
            _userSpeech = response.question;
            _assistantReply = response.reply;
            _state = AssistantState.speaking;
            _statusText = 'Speaking reply...';
          });

          widget.onInteractionComplete?.call(response.question, response.reply);
          await widget.voiceService.playVoiceResponse(response);
        } else if (mounted) {
          setState(() {
            _state = AssistantState.idle;
            _statusText = 'No speech detected. Try again.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _state = AssistantState.idle;
            _statusText = 'Error connecting to backend.';
          });
        }
      }
    } else if (_state == AssistantState.speaking) {
      await widget.voiceService.stopSpeaking();
      setState(() {
        _state = AssistantState.idle;
        _statusText = 'Speech stopped. Tap to speak.';
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

  void _showSettings() {
    final textController =
        TextEditingController(text: widget.voiceService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backend URL', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: 'http://10.0.2.2:8000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => textController.text = 'http://10.0.2.2:8000',
                ),
                ActionChip(
                  label: const Text('iOS (localhost)', style: TextStyle(fontSize: 11)),
                  onPressed: () => textController.text = 'http://localhost:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.voiceService.setBaseUrl(textController.text);
              Navigator.pop(ctx);
              _checkServer();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Premium dark glassmorphism
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),

          // Header with status indicator & settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnline ? Colors.greenAccent : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (_isOnline ? Colors.greenAccent : Colors.redAccent)
                              .withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'FastAPI Connected' : 'FastAPI Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isOnline ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                onPressed: _showSettings,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Transcribed / Response Card
          if (_userSpeech.isNotEmpty || _assistantReply.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userSpeech.isNotEmpty) ...[
                    Row(
                      children: const [
                        Icon(Icons.mic, size: 14, color: Colors.cyanAccent),
                        SizedBox(width: 6),
                        Text(
                          'You said:',
                          style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userSpeech,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const Divider(color: Colors.white10, height: 16),
                  ],
                  if (_assistantReply.isNotEmpty) ...[
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, size: 14, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 6),
                        Text(
                          'Assistant:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _assistantReply,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

          // Central Visualizer & Button
          SizedBox(
            height: 140,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Concentric ripples when LISTENING
                  if (_state == AssistantState.listening)
                    ...List.generate(3, (index) {
                      final wave = (_pulseController.value + (index / 3.0)) % 1.0;
                      final radius = 35.0 + (wave * 35.0) + (_amplitude * 15.0);
                      final opacity = (1.0 - wave).clamp(0.0, 0.6);
                      return Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(opacity),
                            width: 2,
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
                          width: 86,
                          height: 86,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [Colors.transparent, Colors.cyanAccent, Colors.purpleAccent, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Idle breathe aura
                  if (_state == AssistantState.idle)
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (_, __) => Container(
                        width: 74 + (_breatheController.value * 8),
                        height: 74 + (_breatheController.value * 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6366F1).withOpacity(0.18),
                        ),
                      ),
                    ),

                  // Core Mic Button
                  GestureDetector(
                    onTap: _toggleVoice,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _state == AssistantState.listening
                              ? [const Color(0xFFE11D48), const Color(0xFFF43F5E)]
                              : _state == AssistantState.speaking
                                  ? [const Color(0xFF8B5CF6), const Color(0xFF06B6D4)]
                                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_state == AssistantState.listening
                                    ? Colors.redAccent
                                    : const Color(0xFF6366F1))
                                .withOpacity(0.4),
                            blurRadius: 18,
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
                          size: 32,
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _state == AssistantState.listening
                  ? Colors.redAccent
                  : _state == AssistantState.thinking
                      ? Colors.cyanAccent
                      : Colors.white70,
            ),
          ),

          if (_state == AssistantState.speaking) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Stop Speaking'),
              onPressed: () async {
                await widget.voiceService.stopSpeaking();
                setState(() {
                  _state = AssistantState.idle;
                  _statusText = 'Speech stopped.';
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
