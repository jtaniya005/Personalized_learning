import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class VoiceResponse {
  final String question;
  final String reply;
  final String? audioBase64;
  final String ttsProvider;

  VoiceResponse({
    required this.question,
    required this.reply,
    this.audioBase64,
    required this.ttsProvider,
  });

  factory VoiceResponse.fromJson(Map<String, dynamic> json, {String? defaultQuestion}) {
    return VoiceResponse(
      question: json['question'] as String? ?? defaultQuestion ?? '',
      reply: json['reply'] as String? ?? '',
      audioBase64: json['audio_base64'] as String?,
      ttsProvider: json['tts_provider'] as String? ?? 'browser',
    );
  }
}

class VoiceAssistantService {
  static const String _keySessionId = 'voice_chat_session_id';
  static const String _keyBaseUrl = 'voice_chat_base_url';

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final http.Client _client = http.Client();

  String _baseUrl = '';
  String _sessionId = '';
  bool _isSpeaking = false;
  bool _isRecording = false;

  final StreamController<bool> _speakingStateController =
      StreamController<bool>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  Timer? _amplitudeTimer;

  bool get isSpeaking => _isSpeaking;
  bool get isRecording => _isRecording;
  String get baseUrl => _baseUrl;
  String get sessionId => _sessionId;
  Stream<bool> get speakingStream => _speakingStateController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  static String getDefaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? getDefaultBaseUrl();
    _sessionId = prefs.getString(_keySessionId) ?? const Uuid().v4();
    prefs.setString(_keySessionId, _sessionId);

    _initAudioListeners();
  }

  void _initAudioListeners() {
    _player.onPlayerComplete.listen((_) => _finishSpeaking());
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _finishSpeaking();
      }
    });

    _tts.setStartHandler(() {
      _isSpeaking = true;
      _speakingStateController.add(true);
    });
    _tts.setCompletionHandler(() => _finishSpeaking());
    _tts.setCancelHandler(() => _finishSpeaking());
    _tts.setErrorHandler((_) => _finishSpeaking());
  }

  void _finishSpeaking() {
    _isSpeaking = false;
    _speakingStateController.add(false);
  }

  Future<void> setBaseUrl(String url) async {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    _baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
  }

  Future<bool> checkHealth() async {
    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Request microphone permission and start recording
  Future<bool> startRecording() async {
    if (kIsWeb) {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) return false;
    } else {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    if (_isSpeaking) await stopSpeaking();

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
      numChannels: 1,
    );

    if (kIsWeb) {
      await _recorder.start(config, path: '');
    } else {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(config, path: filePath);
    }
    _isRecording = true;

    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isRecording) return;
      try {
        final amp = await _recorder.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      } catch (_) {}
    });

    return true;
  }

  /// Stops recording and sends audio to POST /api/ask
  Future<VoiceResponse?> stopRecordingAndSend() async {
    _amplitudeTimer?.cancel();
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null) return null;

    final uri = Uri.parse('$_baseUrl/api/ask');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['X-Session-ID'] = _sessionId;

    final isWav = path.toLowerCase().endsWith('.wav');
    final mediaType = isWav ? MediaType('audio', 'wav') : MediaType('audio', 'm4a');

    if (kIsWeb) {
      final audioBytes = await http.readBytes(Uri.parse(path));
      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes,
            filename: isWav ? 'rec.wav' : 'rec.m4a', contentType: mediaType),
      );
    } else {
      final file = File(path);
      if (!await file.exists()) return null;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path, contentType: mediaType),
      );
    }

    final streamedResponse =
        await _client.send(request).timeout(const Duration(seconds: 40));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return VoiceResponse.fromJson(data);
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// Cancels active recording
  Future<void> cancelRecording() async {
    _amplitudeTimer?.cancel();
    if (!_isRecording) return;
    await _recorder.cancel();
    _isRecording = false;
  }

  /// Sends text prompt to POST /api/chat
  Future<VoiceResponse> sendTextMessage(String message) async {
    if (_isSpeaking) await stopSpeaking();

    final uri = Uri.parse('$_baseUrl/api/chat');
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Session-ID': _sessionId,
          },
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 35));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return VoiceResponse.fromJson(data, defaultQuestion: message);
    } else {
      throw Exception('Chat server error: ${response.statusCode}');
    }
  }

  /// Clears session history via POST /api/reset
  Future<bool> resetSession() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/reset');
      final res = await _client.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Session-ID': _sessionId,
        },
      ).timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Plays audio response (base64 or TTS fallback)
  Future<void> playVoiceResponse(VoiceResponse response) async {
    await stopSpeaking();

    final hasAudio = response.audioBase64 != null &&
        response.audioBase64!.trim().isNotEmpty &&
        response.ttsProvider != 'browser';

    if (hasAudio) {
      try {
        _isSpeaking = true;
        _speakingStateController.add(true);

        var clean = response.audioBase64!.trim();
        if (clean.contains(',')) clean = clean.split(',').last;
        final bytes = base64Decode(clean);

        await _player.play(BytesSource(bytes));
        return;
      } catch (e) {
        debugPrint('Server audio failed, falling back to TTS: $e');
      }
    }

    // TTS Fallback
    if (response.reply.trim().isNotEmpty) {
      try {
        _isSpeaking = true;
        _speakingStateController.add(true);
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        await _tts.setLanguage('en-US');
        await _tts.speak(response.reply);
      } catch (e) {
        debugPrint('TTS fallback failed: $e');
        _finishSpeaking();
      }
    }
  }

  /// Stops audio or speech playback
  Future<void> stopSpeaking() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    _finishSpeaking();
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _speakingStateController.close();
    _amplitudeController.close();
    _recorder.dispose();
    _player.dispose();
    _client.close();
  }
}
