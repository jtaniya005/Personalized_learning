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
    await stop();

    _playbackCompleter = Completer<void>();

    final hasServerAudio = audioBase64 != null &&
        audioBase64.trim().isNotEmpty &&
        ttsProvider != 'browser';

    if (hasServerAudio) {
      try {
        _currentMode = PlaybackMode.serverAudio;
        _speakingStateController.add(true);

        var cleanBase64 = audioBase64.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last.trim();
        }

        final Uint8List audioBytes = base64Decode(cleanBase64);

        if (kIsWeb) {
          await _audioPlayer.play(BytesSource(audioBytes));
        } else {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
              '${tempDir.path}/reply_${DateTime.now().millisecondsSinceEpoch}.mp3');
          await tempFile.writeAsBytes(audioBytes, flush: true);
          await _audioPlayer.play(DeviceFileSource(tempFile.path));
        }

        return _playbackCompleter!.future;
      } catch (e) {
        debugPrint('Server audio playback failed: $e, falling back to TTS');
        // Fall through to TTS
      }
    }

    // Fallback: Device TTS
    if (text.trim().isNotEmpty) {
      try {
        _currentMode = PlaybackMode.deviceTts;
        _speakingStateController.add(true);

        await _flutterTts.setSpeechRate(speechRate);
        await _flutterTts.setPitch(pitch);
        await _flutterTts.setVolume(1.0);

        final result = await _flutterTts.speak(text.trim());
        if (result == 1) {
          return _playbackCompleter!.future;
        } else {
          _finishPlayback();
        }
      } catch (e) {
        debugPrint('TTS failed: $e');
        _finishPlayback();
      }
    } else {
      _finishPlayback();
    }
  }

  /// Stops any currently playing audio or TTS
  Future<void> stop() async {
    try {
      if (_currentMode == PlaybackMode.serverAudio) {
        await _audioPlayer.stop();
      } else if (_currentMode == PlaybackMode.deviceTts) {
        await _flutterTts.stop();
      }
    } catch (_) {}
    _finishPlayback();
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _speakingStateController.close();
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}
