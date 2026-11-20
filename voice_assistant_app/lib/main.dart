import 'package:flutter/material.dart';
import 'controllers/voice_assistant_controller.dart';
import 'screens/voice_assistant_screen.dart';
import 'services/api_service.dart';
import 'services/audio_playback_service.dart';
import 'services/audio_recording_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent preferences
  final prefsService = await PreferencesService.init();

  // Initialize core services
  final apiService = ApiService(baseUrl: prefsService.getBaseUrl());
  final recordingService = AudioRecordingService();
  final playbackService = AudioPlaybackService();

  // Initialize main controller
  final controller = VoiceAssistantController(
    preferencesService: prefsService,
    apiService: apiService,
    recordingService: recordingService,
    playbackService: playbackService,
  );

  runApp(VoiceAssistantApp(controller: controller));
}

class VoiceAssistantApp extends StatelessWidget {
  final VoiceAssistantController controller;

  const VoiceAssistantApp({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: VoiceAssistantScreen(controller: controller),
    );
  }
}
