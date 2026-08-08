import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'state/app_settings.dart';
import 'screens/splash_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LearnBuddyApp());
}

class LearnBuddyApp extends StatelessWidget {
  const LearnBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilding MaterialApp with a fresh theme on dark-mode toggle is
    // the standard Flutter pattern — it does NOT reset the Navigator,
    // and it correctly cascades to every screen already on the stack
    // because they all read Theme.of(context) for text styling.
    return AnimatedBuilder(
      animation: isDarkNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Learn Buddy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: const SplashScreen(),
          // AppLocale sits above the Navigator so it survives every
          // push/pop — toggling language updates all live screens
          // instantly, the same way Theme does for dark mode.
          builder: (context, child) => AppLocale(
            notifier: languageNotifier,
            child: child!,
          ),
        );
      },
    );
  }
}
