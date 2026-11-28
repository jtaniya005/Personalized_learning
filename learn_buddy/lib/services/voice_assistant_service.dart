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
import 'auth_service.dart';
import '../config/api_config.dart';

class VoiceResponse {
  final String question;
  final String reply;
  final String? audioBase64;
  final String ttsProvider;
  final bool careerGrounded;

  VoiceResponse({
    required this.question,
    required this.reply,
    this.audioBase64,
    required this.ttsProvider,
    this.careerGrounded = false,
  });

  factory VoiceResponse.fromJson(Map<String, dynamic> json, {String? defaultQuestion}) {
    return VoiceResponse(
      question: json['question'] as String? ?? defaultQuestion ?? '',
      reply: json['reply'] as String? ?? '',
      audioBase64: json['audio_base64'] as String?,
      ttsProvider: json['tts_provider'] as String? ?? 'browser',
      careerGrounded: json['career_grounded'] as bool? ?? false,
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
    return ApiConfig.baseUrl;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_keyBaseUrl);
    if (savedUrl != null && savedUrl.trim().startsWith('http')) {
      _baseUrl = ApiConfig.cleanUrl(savedUrl);
    } else {
      _baseUrl = ApiConfig.baseUrl;
    }
    _sessionId = prefs.getString(_keySessionId) ?? const Uuid().v4();
    await prefs.setString(_keySessionId, _sessionId);

    // Auto-detect local live port only if using a local host
    if (!_baseUrl.startsWith('https://')) {
      for (final port in [2500, 8000, 8001]) {
        try {
          final host = ApiConfig.getLocalBaseUrl(port: port);
          final res = await _client.get(Uri.parse('$host/api/health')).timeout(const Duration(milliseconds: 700));
          if (res.statusCode == 200) {
            _baseUrl = host;
            break;
          }
        } catch (_) {}
      }
    }

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
    final cleaned = ApiConfig.cleanUrl(url);
    _baseUrl = cleaned;
    await ApiConfig.setBaseUrl(cleaned);
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

    final user = AuthService.currentUser;
    final payload = {
      'message': message,
      'user_id': user?['id'] ?? _sessionId,
      'name': user?['name'] ?? 'Student',
      'student_class': user?['student_class'] ?? 10,
      'stream': user?['stream'],
      'performance_category': user?['performance_category'] ?? 'average',
      'weak_subjects': user?['weak_subjects'] ?? [],
      'language': 'hi',
    };

    // Try primary base URL, then fallback port if needed
    final candidateUrls = [
      _baseUrl,
      _baseUrl.contains('8001') ? _baseUrl.replaceAll('8001', '8000') : _baseUrl.replaceAll('8000', '8001'),
    ];

    for (final base in candidateUrls) {
      try {
        final uri = Uri.parse('$base/api/chat');
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Session-ID': _sessionId,
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _baseUrl = base;
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return VoiceResponse.fromJson(data, defaultQuestion: message);
        }
      } catch (e) {
        debugPrint('[VoiceAssistantService] attempt on $base failed: $e');
      }
    }

    throw Exception('Failed to connect to backend on port 8000 or 8001.');
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

        if (kIsWeb) {
          try {
            await _player.play(BytesSource(bytes));
          } catch (_) {
            await _player.play(UrlSource('data:audio/mp3;base64,$clean'));
          }
        } else {
          await _player.play(BytesSource(bytes));
        }
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
