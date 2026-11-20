# Voice Assistant App (Flutter)

A dedicated, high-performance **Voice Assistant Client** built with **Flutter (Dart 3.13+)**. This client provides hands-free speech interaction, streaming audio playback, real-time waveform visualizers, connection health monitoring, and customizable backend endpoints.

It serves as both an independent voice interaction companion and a standalone testbed for voice AI pipelines.

---

## 🎨 UI & Aesthetics

Built on a **Dark Glassmorphism** design language (`AppTheme.darkTheme`):
- **Frosted Glass Cards**: Translucent dark surfaces with subtle borders and blurred backdrops (`lib/widgets/glass_card.dart`).
- **Interactive Mic Orb**: Central glowing microphone button with dynamic state animations: *Idle*, *Listening (pulsing wave)*, *Thinking (spinning gradient indicator)*, and *Speaking (breathing glow)*.
- **Waveform Visualizer**: Multi-bar audio visualizer reacting dynamically to incoming microphone amplitude in real time.
- **Connection Badge**: Live indicator badge showing server connectivity (*Online*, *Offline*, *Connecting*).

---

## ⚡ Key Capabilities

- **Audio Capture & Streaming**: Records high-fidelity speech using the `record` package (AAC/M4A/WAV encoding) and streams audio data via multipart form requests.
- **Synthesized Voice Playback**: Seamlessly plays back server-generated base64 audio responses using `audioplayers`.
- **Client-Side TTS Fallback**: Automatically invokes on-device speech synthesis using `flutter_tts` if server audio is absent.
- **Interactive Conversation History**: Chat feed displaying transcribed student speech alongside assistant responses, complete with timestamps and audio replay buttons.
- **Dynamic Endpoint Configuration**: Built-in settings dialog allowing users to switch backend base URLs (e.g. `http://10.0.2.2:8000` for Android emulators, `http://localhost:8000`, or a remote server URL) with an integrated connection ping test.
- **Session Management**: Automatically provisions and stores a persistent session UUID in `shared_preferences` (`X-Session-ID` header) to maintain dialogue state across turns.

---

## 📡 API Contract

The client communicates with the backend via the following interface:

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/health` | Verifies server availability and readiness |
| `POST` | `/api/ask` | Sends recorded audio file via multipart form; returns transcribed text, AI reply, and synthesized audio |
| `POST` | `/api/chat` | Text fallback sending JSON `{"message": "..."}`; returns AI reply |
| `POST` | `/api/reset` | Clears conversation context for the current session ID |

---

## 📂 Project Architecture

```
voice_assistant_app/
├── lib/
│   ├── main.dart                               # Application bootstrap & dependency injection
│   ├── controllers/
│   │   └── voice_assistant_controller.dart     # Central state machine managing recording, playback, and network
│   ├── models/
│   │   ├── api_responses.dart                  # Models for AskResponse, ChatResponse, HealthResponse
│   │   └── chat_message.dart                   # Chat message representation (role, text, audio, timestamp)
│   ├── screens/
│   │   └── voice_assistant_screen.dart         # Main UI holding chat list, waveform, and mic button
│   ├── services/
│   │   ├── api_service.dart                    # HTTP client for ask, chat, reset, and health endpoints
│   │   ├── audio_playback_service.dart         # AudioPlayers and FlutterTTS playback coordinator
│   │   ├── audio_recording_service.dart        # Microphone permissions and audio capture logic
│   │   └── preferences_service.dart            # SharedPreferences wrapper for session & server URL
│   ├── theme/
│   │   └── app_theme.dart                      # Dark theme, glassmorphic styling, and color schemes
│   └── widgets/
│       ├── animated_mic_button.dart            # Pulsing and rotating interactive mic button
│       ├── chat_bubble.dart                    # User/Assistant message bubble with audio replay
│       ├── connection_status_badge.dart        # Live server status badge (Online/Offline)
│       ├── glass_card.dart                     # Reusable glassmorphic styled card container
│       ├── settings_dialog.dart                # Modal to configure and test backend server URL
│       └── waveform_visualizer.dart            # Amplitude-responsive soundwave visualizer bars
└── pubspec.yaml                                # Flutter dependencies
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.13+)
- Android / iOS device or emulator with microphone permissions enabled

### Setup & Run

```bash
cd voice_assistant_app

# 1. Fetch dependencies
flutter pub get

# 2. Run the app
flutter run
```

### Configuring Backend Connection
1. Launch the app.
2. Tap the **Settings (gear)** icon in the top right app bar.
3. Enter your backend host:
   - **Android Emulator**: `http://10.0.2.2:8000`
   - **iOS Simulator / Desktop**: `http://localhost:8000`
   - **Physical Device**: `http://<YOUR_LOCAL_IP>:8000`
4. Tap **"Test Connection"** to verify the health check passes, then save.
