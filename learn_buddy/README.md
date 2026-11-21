# Learn Buddy — Mobile Application (Flutter)

A personalized study companion app built for **Class 10 and 12** students. Instead of waiting to be asked questions, the AI mentor — **Buddy** — proactively checks in, analyzes weak subject areas from student marksheets, structures study plans, and motivates students throughout their academic journey.

Built with **Flutter (Dart 3.3+)**, featuring Firebase Authentication, Tesseract OCR integration, local multilingual support (English & Hindi), brain break mini-games, and an integrated voice assistant modal.

---

## 🎨 Design System — "Notebook & Marigold"

Designed to depart from generic edtech blue gradients and evoke the tactile, focused experience of a student's personal study notebook:

- **Palette**: Paper cream (`#FBF7EF`), deep ink (`#20262B`), marigold highlighter (`#FFA531`), coral red (`#FF6F59`), and sage green (`#3FA06A`).
- **Typography**: 
  - **Headings**: *Fraunces* (expressive serif font giving an editorial, bookish feel)
  - **Body text**: *Plus Jakarta Sans* (clean, highly legible modern sans-serif)
  - **Metadata & Tags**: *Space Mono* (technical tags, chapter badges, and timestamps)
- **Signature UI Elements**:
  - `NotebookCard`: Cards styled with spiral-binder punch holes along the left edge and realistic paper textures.
  - `AnimatedScalePress`: Tactile physical micro-interactions on button and card taps.
  - `AppLogo`: Custom layered book mark with a spark emblem.

---

## 📱 Core Features & User Journey

```
Splash Screen
    │
    ▼
Onboarding Slides (3 Steps: Personalization, AI Mentor, Progress)
    │
    ▼
Auth Choice ("Log In" vs "I'm New Here")
    ├── Login Flow: Email + Password, Google Sign-In, Phone OTP
    └── Register Flow: Name, Email, Password, Class (10/12), Avatar Picker,
                       Weak Subjects multi-select, Daily Goal stepper
    │
    ▼
Main Shell (Bottom Navigation)
    ├── 🏠 Home: Proactive Buddy greeting, streak counter, daily quote, subject cards
    ├── 📚 Study Material: Subjects, chapters categorized by "Exam favourite", "Weak area", "Quick revise"
    ├── 🤖 Buddy (AI Chat): Proactive study planning check-ins, multi-language chat (EN/HI/Hinglish)
    ├── 📊 Progress: Streak stats, 7-day activity chart, syllabus coverage, marksheet OCR upload
    ├── 🎮 Brain Break: Mini-games (Math Sprint, Memory Match, Tic-Tac-Toe)
    └── ⚙️ Settings: Profile editor, Dark Mode toggle, EN/HI language switcher, Buddy tone preferences
```

---

## 🌟 Highlighted Modules

### 1. Integrated Voice Assistant Modal
Accessible directly from within the app, students can tap the microphone icon to launch an interactive voice sheet:
- Real-time microphone audio recording via `record`.
- Dynamic voice amplitude wave animations.
- Plays backend audio replies using `audioplayers` or falls back to `flutter_tts`.
- Toggleable server backend host (supports Android emulator `10.0.2.2:8000` or local network IP).

### 2. Marksheet OCR Scanner
- Allows students to upload their previous grade marksheet (PDF or image).
- Pre-extracts data client-side (using `google_mlkit_text_recognition`) and uploads to the backend (`/api/v1/students/me/marksheet/extract`).
- Automatically updates student profile with identified weak subjects and past percentage.

### 3. Brain Break Mini-Games (`lib/screens/games/`)
Gamified mental recharge modules to refresh students between intense study sessions:
- **Math Sprint**: Quick-fire mental arithmetic against the clock.
- **Memory Match**: Card-flipping cognitive concentration game.
- **Tic-Tac-Toe**: Classic strategy puzzle.
- Features custom confetti particle overlays and celebration dialogs.

### 4. Dynamic Localization & Dark Mode
- Global reactive state (`lib/state/app_settings.dart`) propagates dark mode and language (`EN` / `HI`) instantly without app restarts.
- Uses `tr(context, 'key')` helper throughout the UI for seamless string translation.

---

## 🛠 Project Structure

```
learn_buddy/
├── lib/
│   ├── firebase_options.dart         # Generated Firebase configuration
│   ├── main.dart                     # App entry point & AppLocale wrapper
│   ├── models/
│   │   ├── mock_data.dart            # Mock curriculum, chapters, and topics
│   │   └── subject_utils.dart        # Stream and class subject mapper
│   ├── screens/
│   │   ├── ai_chat_screen.dart       # Buddy conversational interface
│   │   ├── auth_choice_screen.dart   # Login vs Sign Up selection
│   │   ├── home_screen.dart          # Main student dashboard
│   │   ├── login_screen.dart         # Authentication screen
│   │   ├── onboarding_screen.dart    # 3-step feature introduction
│   │   ├── phone_otp_screen.dart     # Mobile OTP verification
│   │   ├── progress_screen.dart      # Analytics & Marksheet scanner
│   │   ├── register_screen.dart      # Student registration & onboarding
│   │   ├── settings_screen.dart      # User preferences & profile settings
│   │   ├── splash_screen.dart        # Animated splash
│   │   ├── study_material_screen.dart# Chapters and study notes
│   │   └── games/                    # Brain Break mini-games
│   │       ├── brain_break_menu.dart
│   │       ├── math_sprint_game.dart
│   │       ├── memory_match_game.dart
│   │       └── tic_tac_toe_game.dart
│   ├── services/
│   │   ├── auth_service.dart         # Firebase Auth & FastAPI profile sync
│   │   └── voice_assistant_service.dart # Recording, TTS, & voice API
│   ├── state/
│   │   └── app_settings.dart         # ValueNotifiers for theme & language
│   ├── theme/
│   │   └── app_theme.dart            # AppColors, typography, & input styling
│   └── widgets/
│       ├── animated_scale_press.dart # Tappable press bounce animation
│       ├── app_logo.dart             # Custom SVG book badge
│       ├── confetti_overlay.dart     # Game celebration confetti
│       ├── notebook_card.dart        # Spiral notebook styled container
│       └── voice_assistant_modal.dart# Voice dialog with animated waves
├── assets/                           # Local images, badges, and fonts
└── pubspec.yaml                      # Project dependencies & assets
```

---

## 🚀 Running the App

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.19+)
- Android Studio / Xcode for mobile emulators

### 2. Configure Firebase
Ensure your Firebase configuration is linked:
```bash
# If using FlutterFire CLI:
flutterfire configure
```

### 3. Run the App
```bash
cd learn_buddy

# Fetch Flutter dependencies
flutter pub get

# Run on an attached device or emulator
flutter run
```

> **Backend Connectivity**: By default, `AuthService` targets:
> - Android Emulator: `http://10.0.2.2:8000/api/v1`
> - iOS Simulator / Desktop / Web: `http://localhost:8000/api/v1`
> Ensure your FastAPI backend (`learn_buddy_backend`) is running.
