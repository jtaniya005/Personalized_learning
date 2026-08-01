# Learn Buddy (UI)

Flutter UI for a Class 10/12 study app where an AI mentor — "Buddy" —
proactively checks in and guides what to study next, instead of just
answering questions when asked.

## Design system — "Notebook & Marigold"
Built to avoid the generic edtech blue/gradient look — pulls instead
from the school notebook: cream ruled paper, ink, and a bright
marigold highlighter accent.

- **Colors**: paper cream `#FBF7EF`, ink `#20262B`, marigold `#FFA531`,
  coral `#FF6F59`, sage `#3FA06A`, sky-ink `#2F5D6B`, plus teal
  `#20B2A6` and grape `#8C6FE6` for avatar/logo variety.
- **Type**: Fraunces (display/headings) + Plus Jakarta Sans (body) +
  Space Mono (small labels/tags).
- **Logo**: `widgets/app_logo.dart` — a layered book badge (learning)
  with a spark accent badge (the "buddy"), not a text monogram, so it
  reads as a real mark at any size and doubles as an app-icon source.
- **Signature card**: `NotebookCard` — spiral-binder holes on the left
  edge, with a press-scale micro-interaction on every tappable one.

## Dark mode & language (EN/HI)
- `state/app_settings.dart` — two global toggles, propagated the same
  way Theme does (survives navigation, no app restart):
  - `isDarkNotifier` — dark mode. `AppColors` surface/text colors
    (paper, card, rule, ink) are dynamic getters that read this; accent
    colors (marigold, coral, sage, etc.) stay constant across themes.
  - `languageNotifier` — 'en' / 'hi'. Propagated via a custom
    `AppLocale` InheritedWidget wrapped around the Navigator in
    `main.dart`'s `builder`. Call `tr(context, 'key')` anywhere to get
    translated text — it also registers that widget to rebuild when
    the language changes.
- `settings_screen.dart` — reachable via the gear icon on Home:
  - **Profile** — avatar/name/class, tap to edit in a bottom sheet;
    changes flow back to Home via `Navigator.pop(result)`
  - **Appearance** — Dark Mode switch, EN/HI language toggle
  - **Notifications** — daily reminder (with time picker), streak alerts
  - **Study preferences** — daily study goal (stepper), Buddy's tone
    (Friendly / Strict / Motivational — feed this into your LangGraph
    system prompt to actually change Buddy's personality)
  - **About & Help** — rate app, feedback, support, terms, version
  - **Log out** — clears the navigation stack back to Auth Choice
- There's no separate language-selection screen anymore — the app
  defaults to English and language lives in Settings, changeable
  anytime, same as dark mode.
- Subject names and chapter titles are curriculum content (not in the
  `tr()` dictionary) — localize those from your backend/database.

## Flow
Splash → Language select (English default) → Onboarding (3 slides) →
**Auth choice** ("Log in" vs "I'm new here") →
**Login** (existing users: email + password, Google, Phone OTP) or
**Register** (new users: name, email, password, class, avatar picker,
Google, Phone OTP) → Home (bottom-nav: Home, Study, Buddy, Progress)

Class is only asked once, at registration — login never asks again.
The choice screen keeps "I already have an account" and "I'm new here"
as two equally visible options, instead of defaulting everyone into
one form with a small signup link at the bottom.

## Screens included
- `splash_screen.dart` — animated logo mark
- `language_select_screen.dart` — sets app + chat language, English default
- `onboarding_screen.dart` — 3 slides (personalized material, AI mentor,
  progress tracking)
- `auth_choice_screen.dart` — "Log in" vs "I'm new here", the fork
  between returning and new students
- `login_screen.dart` — email/password, Google, Phone OTP
- `register_screen.dart` — name, email, password, confirm, class picker,
  icon-based avatar picker (8 Material icons w/ gradient backgrounds,
  no emoji), **weak subjects** multi-select (feeds Buddy's
  personalization — stored in `weakSubjectsNotifier`), **daily study
  goal** stepper (stored in `dailyGoalMinutes`), Google, Phone OTP
- `phone_otp_screen.dart` — phone number → 4-digit code, shared by both
  login and register flows
- `home_screen.dart` — avatar in the greeting, streak, a daily quote
  card, Buddy's proactive nudge, subject grid
- `study_material_screen.dart` — subject chips + chapter list tagged
  "Exam favourite" / "Weak area" / "Quick revise"
- `ai_chat_screen.dart` — Buddy opens the conversation itself (typing →
  observation → a structured "Today's plan" check-in card with Accept/
  Later actions), plus a per-chat language switcher (English/Hindi/
  Hinglish) independent of the app-wide language
- `progress_screen.dart` — streak/avg-score/weak-spot stat tiles, a
  7-day activity chart, subject-wise progress bars, and a
  "practice these first" list built from every "Weak area" chapter

All data is mocked in `lib/models/mock_data.dart` — swap with your
FastAPI + RAG/LangGraph responses when the backend is ready.

## Run it
```bash
flutter pub get
flutter run
```

## Next wiring points (for your backend)
- `register_screen.dart` → `_createAccount()` — replace with your real
  sign-up call (store name, email, password hash, class, avatar).
- `login_screen.dart` → `_goHome()` — replace with your auth call;
  fetch the student's saved class/name/avatar instead of the hardcoded
  defaults shown here.
- `phone_otp_screen.dart` → wire to Firebase Auth or your SMS/OTP
  provider; both "Send code" and "Verify" are currently just UI state.
- `ai_chat_screen.dart` → the intro sequence (`_runIntroSequence`) and
  the check-in card are exactly where your LangGraph "check-in" node
  should plug in — it should look at real student activity (streak,
  last-studied chapter, weak areas) to decide what Buddy opens with,
  instead of the hardcoded Trigonometry example here. `chatLanguage`
  should be passed to your backend so replies come back in the chosen
  language.
- `mock_data.dart` → replace subjects/chapters with data fetched per
  student class from your database.
