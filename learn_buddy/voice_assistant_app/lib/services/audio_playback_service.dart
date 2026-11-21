import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

enum PlaybackMode { idle, serverAudio, deviceTts }

class AudioPlaybackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  PlaybackMode _currentMode = PlaybackMode.idle;
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerStateSub;
  Completer<void>? _playbackCompleter;

  final StreamController<bool> _speakingStateController =
      StreamController<bool>.broadcast();

  bool get isSpeaking => _currentMode != PlaybackMode.idle;
  Stream<bool> get speakingStream => _speakingStateController.stream;

  AudioPlaybackService() {
    _initTts();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      _finishPlayback();
    });

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (_currentMode == PlaybackMode.serverAudio) {
          _finishPlayback();
        }
      }
    });
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _currentMode = PlaybackMode.deviceTts;
      _speakingStateController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _finishPlayback();
    });

    _flutterTts.setCancelHandler(() {
      _finishPlayback();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _finishPlayback();
    });
  }

  void _finishPlayback() {
    _currentMode = PlaybackMode.idle;
    _speakingStateController.add(false);
    if (_playbackCompleter != null && !_playbackCompleter!.isCompleted) {
      _playbackCompleter!.complete();
    }
    _playbackCompleter = null;
  }

  /// Plays server audio (from base64) or falls back to on-device TTS.
  /// Returns a Future that completes when playback finishes or is stopped.
  Future<void> playReply({
    required String text,
    String? audioBase64,
    String? ttsProvider,
    double speechRate = 0.5,
    double pitch = 1.0,
  }) async {
    // Stop any existing playback first
    await stop();

    _playbackCompleter = Completer<void>();

    final hasServerAudio = audioBase64 != null &&
        audioBase64.trim().isNotEmpty &&
        ttsProvider != 'browser';

    if (hasServerAudio) {
      try {
        _currentMode = PlaybackMode.serverAudio;
        _speakingStateController.add(true);

        // Clean base64 string if data url prefix is attached
        var cleanBase64 = audioBase64.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }

        final Uint8List audioBytes = base64Decode(cleanBase64);

        // Save to temporary file for best compatibility across devices
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/assistant_reply_$timestamp.mp3');
        await tempFile.writeAsBytes(audioBytes, flush: true);

        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        return _playbackCompleter!.future;
      } catch (e) {
        debugPrint('Failed to play server audio: $e. Falling back to TTS.');
        // Fallback to TTS
      }
    }

    // Fallback to on-device TTS
    if (text.trim().isNotEmpty) {
      try {
        _currentMode = PlaybackMode.deviceTts;
        _speakingStateController.add(true);

        await _flutterTts.setSpeechRate(speechRate);
        await _flutterTts.setPitch(pitch);
        await _flutterTts.setLanguage('en-US');

        await _flutterTts.speak(text);
        return _playbackCompleter!.future;
      } catch (e) {
        debugPrint('TTS failed: $e');
        _finishPlayback();
      }
    } else {
      _finishPlayback();
    }
  }

  /// Stops audio playback or on-device TTS immediately
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      await _flutterTts.stop();
    } catch (_) {}

    _finishPlayback();
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _speakingStateController.close();
    _audioPlayer.dispose();
  }
}
