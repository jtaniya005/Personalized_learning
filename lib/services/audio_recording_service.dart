import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  StreamController<double>? _amplitudeController;
  Timer? _amplitudeTimer;

  bool get isRecording => _isRecording;
  Stream<double>? get amplitudeStream => _amplitudeController?.stream;

  /// Check and request microphone permission using permission_handler
  Future<bool> checkAndRequestPermission() async {
    if (kIsWeb) {
      return await _recorder.hasPermission();
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isDenied) {
      final requested = await Permission.microphone.request();
      return requested.isGranted;
    }
    if (status.isPermanentlyDenied) {
      return false;
    }
    final requested = await Permission.microphone.request();
    return requested.isGranted;
  }

  /// Starts recording microphone audio to a temporary file (.m4a)
  Future<String> startRecording() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/voice_query_$timestamp.m4a';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
      numChannels: 1,
    );

    await _recorder.start(config, path: filePath);
    _isRecording = true;
    _currentRecordingPath = filePath;

    _amplitudeController?.close();
    _amplitudeController = StreamController<double>.broadcast();

    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      try {
        final amp = await _recorder.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        if (!_amplitudeController!.isClosed) {
          _amplitudeController!.add(normalized);
        }
      } catch (_) {}
    });

    return filePath;
  }

  /// Stops recording and returns the File
  Future<File?> stopRecording() async {
    _amplitudeTimer?.cancel();
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    final targetPath = path ?? _currentRecordingPath;
    _currentRecordingPath = null;

    if (targetPath != null) {
      final file = File(targetPath);
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  /// Cancels active recording without returning audio
  Future<void> cancelRecording() async {
    _amplitudeTimer?.cancel();
    if (!_isRecording) return;

    await _recorder.cancel();
    _isRecording = false;
    _currentRecordingPath = null;
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController?.close();
    _recorder.dispose();
  }
}
