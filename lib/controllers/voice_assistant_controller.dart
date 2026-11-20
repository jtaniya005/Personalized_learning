import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/voice_api_responses.dart';
import '../models/voice_chat_message.dart';
import '../services/voice_api_service.dart';
import '../services/audio_playback_service.dart';
import '../services/audio_recording_service.dart';
import '../services/voice_preferences_service.dart';

enum AssistantState {
  idle,
  listening,
  thinking,
  speaking,
}

enum ServerStatus {
  checking,
  online,
  offline,
}

class VoiceAssistantController extends ChangeNotifier {
  final VoicePreferencesService preferencesService;
  final VoiceApiService apiService;
  final AudioRecordingService recordingService;
  final AudioPlaybackService playbackService;

  AssistantState _state = AssistantState.idle;
  ServerStatus _serverStatus = ServerStatus.checking;
  String _serverStatusMessage = 'Connecting to backend...';
  String _sessionId = '';
  String _baseUrl = '';
  bool _ttsEnabled = true;

  final List<VoiceChatMessage> _messages = [];
  double _currentAmplitude = 0.0;
  String? _lastError;
  Timer? _healthCheckTimer;
  StreamSubscription<double>? _amplitudeSub;
  StreamSubscription<bool>? _speakingSub;

  VoiceAssistantController({
    required this.preferencesService,
    required this.apiService,
    required this.recordingService,
    required this.playbackService,
  }) {
    _init();
  }

  static Future<VoiceAssistantController> create() async {
    final prefs = await VoicePreferencesService.init();
    final api = VoiceApiService(baseUrl: prefs.getBaseUrl());
    final rec = AudioRecordingService();
    final play = AudioPlaybackService();
    return VoiceAssistantController(
      preferencesService: prefs,
      apiService: api,
      recordingService: rec,
      playbackService: play,
    );
  }

  AssistantState get state => _state;
  ServerStatus get serverStatus => _serverStatus;
  String get serverStatusMessage => _serverStatusMessage;
  String get sessionId => _sessionId;
  String get baseUrl => _baseUrl;
  bool get ttsEnabled => _ttsEnabled;
  List<VoiceChatMessage> get messages => List.unmodifiable(_messages);
  double get currentAmplitude => _currentAmplitude;
  String? get lastError => _lastError;

  bool get isListening => _state == AssistantState.listening;
  bool get isThinking => _state == AssistantState.thinking;
  bool get isSpeaking => _state == AssistantState.speaking;
  bool get isIdle => _state == AssistantState.idle;

  void _init() {
    _sessionId = preferencesService.getSessionId();
    _baseUrl = preferencesService.getBaseUrl();
    _ttsEnabled = preferencesService.getTtsEnabled();

    _speakingSub = playbackService.speakingStream.listen((isSpeaking) {
      if (!isSpeaking && _state == AssistantState.speaking) {
        _setState(AssistantState.idle);
      }
    });

    checkBackendHealth();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => checkBackendHealth(silent: true),
    );
  }

  void _setState(AssistantState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Pings /api/health to test connectivity
  Future<void> checkBackendHealth({bool silent = false}) async {
    if (!silent) {
      _serverStatus = ServerStatus.checking;
      _serverStatusMessage = 'Checking backend status...';
      notifyListeners();
    }

    try {
      final res = await apiService.checkHealth();
      if (res.isHealthy) {
        _serverStatus = ServerStatus.online;
        _serverStatusMessage = 'Backend connected (${apiService.baseUrl})';
      } else {
        _serverStatus = ServerStatus.offline;
        _serverStatusMessage = 'Backend responded with status: ${res.status}';
      }
    } catch (e) {
      _serverStatus = ServerStatus.offline;
      _serverStatusMessage = 'Cannot connect to ${apiService.baseUrl}';
    }
    notifyListeners();
  }

  /// Updates API Base URL and saves to persistent storage
  Future<void> updateBaseUrl(String newUrl) async {
    await preferencesService.setBaseUrl(newUrl);
    _baseUrl = preferencesService.getBaseUrl();
    apiService.updateBaseUrl(_baseUrl);
    notifyListeners();
    await checkBackendHealth();
  }

  /// Toggles TTS narration playback
  Future<void> toggleTts(bool enabled) async {
    _ttsEnabled = enabled;
    await preferencesService.setTtsEnabled(enabled);
    if (!enabled && isSpeaking) {
      await playbackService.stop();
      _setState(AssistantState.idle);
    }
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool enabled) => toggleTts(enabled);

  Future<void> clearHistory() => resetSession();

  void dismissError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await playbackService.stop();
    if (_state == AssistantState.speaking) {
      _setState(AssistantState.idle);
    }
  }

  Future<void> toggleListening() async {
    if (_state == AssistantState.listening) {
      await stopListeningAndSend();
    } else {
      await startListening();
    }
  }

  /// Starts recording microphone input
  Future<void> startListening() async {
    if (_state != AssistantState.idle) {
      if (_state == AssistantState.speaking) {
        await playbackService.stop();
      } else {
        return;
      }
    }

    _lastError = null;

    try {
      await recordingService.startRecording();
      _setState(AssistantState.listening);

      _amplitudeSub?.cancel();
      _amplitudeSub = recordingService.amplitudeStream?.listen((amp) {
        _currentAmplitude = amp;
        notifyListeners();
      });
    } catch (e) {
      _lastError = 'Microphone access failed: $e';
      _setState(AssistantState.idle);
      _addSystemMessage('Microphone access denied or error occurred.');
    }
  }

  /// Stops recording and dispatches audio to POST /api/ask
  Future<void> stopListeningAndSend() async {
    if (_state != AssistantState.listening) return;

    _amplitudeSub?.cancel();
    _currentAmplitude = 0.0;
    _setState(AssistantState.thinking);

    try {
      final audioFile = await recordingService.stopRecording();
      if (audioFile == null) {
        _setState(AssistantState.idle);
        return;
      }

      final placeholderMsg = VoiceChatMessage(
        text: 'Transcribing voice...',
        sender: MessageSender.user,
        status: MessageStatus.sending,
        isVoice: true,
      );
      _messages.add(placeholderMsg);
      notifyListeners();

      final AskResponse response = await apiService.askAudio(
        audioFile: audioFile,
        sessionId: _sessionId,
      );

      final index = _messages.indexOf(placeholderMsg);
      if (index != -1) {
        _messages[index] = placeholderMsg.copyWith(
          text: response.question.isNotEmpty
              ? response.question
              : '[Voice Query]',
          status: MessageStatus.sent,
        );
      }

      final assistantMsg = VoiceChatMessage(
        text: response.reply,
        sender: MessageSender.assistant,
        isVoice: true,
        audioBase64: response.audioBase64,
        ttsProvider: response.ttsProvider,
      );
      _messages.add(assistantMsg);
      notifyListeners();

      if (_ttsEnabled) {
        _setState(AssistantState.speaking);
        await playbackService.playReply(
          text: response.reply,
          audioBase64: response.audioBase64,
          ttsProvider: response.ttsProvider,
          speechRate: preferencesService.getSpeechRate(),
          pitch: preferencesService.getPitch(),
        );
      } else {
        _setState(AssistantState.idle);
      }
    } catch (e) {
      _lastError = e.toString();
      _setState(AssistantState.idle);
      _addSystemMessage('Failed to process voice query: $e', isError: true);
    }
  }

  /// Cancels active recording without submitting
  Future<void> cancelListening() async {
    if (_state != AssistantState.listening) return;

    _amplitudeSub?.cancel();
    _currentAmplitude = 0.0;
    await recordingService.cancelRecording();
    _setState(AssistantState.idle);
  }

  /// Sends text message fallback to POST /api/chat
  Future<void> sendTextMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    if (isSpeaking) {
      await playbackService.stop();
    }

    final userMsg = VoiceChatMessage(
      text: clean,
      sender: MessageSender.user,
      isVoice: false,
    );
    _messages.add(userMsg);
    _setState(AssistantState.thinking);

    try {
      final ChatResponse res = await apiService.chatText(
        message: clean,
        sessionId: _sessionId,
      );

      final assistantMsg = VoiceChatMessage(
        text: res.reply,
        sender: MessageSender.assistant,
        isVoice: false,
        audioBase64: res.audioBase64,
        ttsProvider: res.ttsProvider,
      );
      _messages.add(assistantMsg);
      notifyListeners();

      if (_ttsEnabled && res.reply.isNotEmpty) {
        _setState(AssistantState.speaking);
        await playbackService.playReply(
          text: res.reply,
          audioBase64: res.audioBase64,
          ttsProvider: res.ttsProvider,
          speechRate: preferencesService.getSpeechRate(),
          pitch: preferencesService.getPitch(),
        );
      } else {
        _setState(AssistantState.idle);
      }
    } catch (e) {
      _lastError = e.toString();
      _setState(AssistantState.idle);
      _addSystemMessage('Chat error: $e', isError: true);
    }
  }

  /// Replays audio for an existing message
  Future<void> replayMessage(VoiceChatMessage msg) async {
    if (isSpeaking) {
      await playbackService.stop();
    }
    _setState(AssistantState.speaking);
    await playbackService.playReply(
      text: msg.text,
      audioBase64: msg.audioBase64,
      ttsProvider: msg.ttsProvider,
      speechRate: preferencesService.getSpeechRate(),
      pitch: preferencesService.getPitch(),
    );
  }

  /// Resets session context on backend and wipes UI messages
  Future<void> resetSession() async {
    if (isSpeaking) await playbackService.stop();
    if (isListening) await cancelListening();

    try {
      await apiService.resetSession(_sessionId);
    } catch (_) {}

    _sessionId = await preferencesService.regenerateSessionId();
    _messages.clear();
    _setState(AssistantState.idle);
    _addSystemMessage('Conversation context has been reset.');
  }

  void _addSystemMessage(String text, {bool isError = false}) {
    _messages.add(VoiceChatMessage(
      text: text,
      sender: MessageSender.system,
      status: isError ? MessageStatus.error : MessageStatus.sent,
    ));
    notifyListeners();
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _amplitudeSub?.cancel();
    _speakingSub?.cancel();
    recordingService.dispose();
    playbackService.dispose();
    apiService.dispose();
    super.dispose();
  }
}
