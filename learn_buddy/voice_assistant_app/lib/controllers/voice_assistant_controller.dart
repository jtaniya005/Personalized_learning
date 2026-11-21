import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api_responses.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/audio_playback_service.dart';
import '../services/audio_recording_service.dart';
import '../services/preferences_service.dart';

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
  final PreferencesService preferencesService;
  final ApiService apiService;
  final AudioRecordingService recordingService;
  final AudioPlaybackService playbackService;

  AssistantState _state = AssistantState.idle;
  ServerStatus _serverStatus = ServerStatus.checking;
  String _serverStatusMessage = 'Connecting to backend...';
  String _sessionId = '';
  String _baseUrl = '';
  bool _ttsEnabled = true;

  final List<ChatMessage> _messages = [];
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

  AssistantState get state => _state;
  ServerStatus get serverStatus => _serverStatus;
  String get serverStatusMessage => _serverStatusMessage;
  String get sessionId => _sessionId;
  String get baseUrl => _baseUrl;
  bool get ttsEnabled => _ttsEnabled;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
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

    // Listen to playback state changes
    _speakingSub = playbackService.speakingStream.listen((isSpeaking) {
      if (!isSpeaking && _state == AssistantState.speaking) {
        _setState(AssistantState.idle);
      }
    });

    // Check backend health immediately and schedule periodic ping
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
        _serverStatusMessage = 'Backend connected (${res.status})';
      } else {
        _serverStatus = ServerStatus.offline;
        _serverStatusMessage = 'Backend reported: ${res.status}';
      }
      _lastError = null;
    } catch (e) {
      _serverStatus = ServerStatus.offline;
      _serverStatusMessage = e.toString();
    }
    notifyListeners();
  }

  /// Update base URL
  Future<void> updateBaseUrl(String newUrl) async {
    await preferencesService.setBaseUrl(newUrl);
    _baseUrl = preferencesService.getBaseUrl();
    apiService.updateBaseUrl(_baseUrl);
    notifyListeners();
    await checkBackendHealth();
  }

  /// Toggle TTS speech output
  Future<void> setTtsEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    await preferencesService.setTtsEnabled(enabled);
    if (!enabled && isSpeaking) {
      await stopSpeaking();
    }
    notifyListeners();
  }

  /// Toggle recording: if idle, start listening; if listening, stop and send
  Future<void> toggleListening() async {
    if (isListening) {
      await stopListeningAndSend();
    } else if (isSpeaking) {
      await stopSpeaking();
      await startListening();
    } else if (isIdle) {
      await startListening();
    }
  }

  /// Starts recording microphone audio
  Future<void> startListening() async {
    if (_state != AssistantState.idle && _state != AssistantState.speaking) {
      return;
    }

    if (isSpeaking) {
      await stopSpeaking();
    }

    _lastError = null;

    try {
      await recordingService.startRecording();
      _setState(AssistantState.listening);

      // Listen to amplitude updates
      _amplitudeSub?.cancel();
      _amplitudeSub = recordingService.amplitudeStream?.listen((amp) {
        _currentAmplitude = amp;
        notifyListeners();
      });
    } catch (e) {
      _lastError = 'Microphone error: $e';
      _setState(AssistantState.idle);
      notifyListeners();
    }
  }

  /// Stops recording and sends audio to POST /api/ask
  Future<void> stopListeningAndSend() async {
    if (!isListening) return;

    _amplitudeSub?.cancel();
    _currentAmplitude = 0.0;
    _setState(AssistantState.thinking);

    try {
      final audioFile = await recordingService.stopRecording();
      if (audioFile == null) {
        _lastError = 'No audio recorded.';
        _setState(AssistantState.idle);
        return;
      }

      // Add a placeholder user voice query while waiting
      final userMsgPlaceholder = ChatMessage(
        text: 'Voice Query (Transcribing...)',
        sender: MessageSender.user,
        isVoice: true,
        status: MessageStatus.sending,
      );
      _messages.add(userMsgPlaceholder);
      notifyListeners();

      final AskResponse response = await apiService.askAudio(
        audioFile: audioFile,
        sessionId: _sessionId,
      );

      // Replace placeholder with transcribed question
      final index = _messages.indexOf(userMsgPlaceholder);
      final finalUserMsg = userMsgPlaceholder.copyWith(
        text: response.question.isNotEmpty
            ? response.question
            : '[Unintelligible speech]',
        status: MessageStatus.sent,
      );

      if (index != -1) {
        _messages[index] = finalUserMsg;
      } else {
        _messages.add(finalUserMsg);
      }

      // Add assistant response message
      final assistantMsg = ChatMessage(
        text: response.reply,
        sender: MessageSender.assistant,
        audioBase64: response.audioBase64,
        ttsProvider: response.ttsProvider,
      );
      _messages.add(assistantMsg);
      notifyListeners();

      // Play audio response if TTS enabled
      if (_ttsEnabled && response.reply.trim().isNotEmpty) {
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
      _messages.add(
        ChatMessage(
          text: 'Error processing voice request: $e',
          sender: MessageSender.system,
          status: MessageStatus.error,
          errorMessage: e.toString(),
        ),
      );
      _setState(AssistantState.idle);
    }
  }

  /// Cancels active listening without sending
  Future<void> cancelListening() async {
    if (!isListening) return;
    _amplitudeSub?.cancel();
    _currentAmplitude = 0.0;
    await recordingService.cancelRecording();
    _setState(AssistantState.idle);
  }

  /// Sends text fallback message to POST /api/chat
  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (isSpeaking) {
      await stopSpeaking();
    }
    if (isListening) {
      await cancelListening();
    }

    final userMessage = ChatMessage(
      text: trimmed,
      sender: MessageSender.user,
      isVoice: false,
    );
    _messages.add(userMessage);
    _setState(AssistantState.thinking);
    notifyListeners();

    try {
      final ChatResponse response = await apiService.chatText(
        message: trimmed,
        sessionId: _sessionId,
      );

      final assistantMsg = ChatMessage(
        text: response.reply,
        sender: MessageSender.assistant,
        audioBase64: response.audioBase64,
        ttsProvider: response.ttsProvider,
      );
      _messages.add(assistantMsg);
      notifyListeners();

      if (_ttsEnabled && response.reply.trim().isNotEmpty) {
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
      _messages.add(
        ChatMessage(
          text: 'Error: $e',
          sender: MessageSender.system,
          status: MessageStatus.error,
          errorMessage: e.toString(),
        ),
      );
      _setState(AssistantState.idle);
    }
  }

  /// Interupts and stops active assistant speech / audio
  Future<void> stopSpeaking() async {
    await playbackService.stop();
    _setState(AssistantState.idle);
  }

  /// Clears conversation history on backend (POST /api/reset) and local state
  Future<void> clearHistory() async {
    if (isSpeaking) await stopSpeaking();
    if (isListening) await cancelListening();

    try {
      await apiService.resetSession(_sessionId);
    } catch (e) {
      debugPrint('Warning: Server reset failed: $e. Clearing local history.');
    }

    _messages.clear();
    _lastError = null;
    notifyListeners();
  }

  /// Clears error message banner
  void dismissError() {
    _lastError = null;
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
