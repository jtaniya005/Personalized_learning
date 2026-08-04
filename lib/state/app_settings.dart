import 'package:flutter/material.dart';

/// Whether the app is in dark mode. Read directly by [AppColors] getters.
/// Toggling this rebuilds MaterialApp's theme, which — because nearly
/// every screen already reads `Theme.of(context)` for text styles —
/// correctly cascades a rebuild to every live screen, including ones
/// already pushed on the Navigator stack.
final ValueNotifier<bool> isDarkNotifier = ValueNotifier(false);

/// Current app language: 'en' or 'hi'. Propagated via [AppLocale] so
/// that toggling it updates every screen instantly without resetting
/// navigation — the same mechanism Theme uses, just for text.
final ValueNotifier<String> languageNotifier = ValueNotifier('en');

// Study preferences and notification settings — read locally within
// Settings/Home, no app-wide propagation needed (unlike theme/language).
final ValueNotifier<int> dailyGoalMinutes = ValueNotifier(30);
final ValueNotifier<String> buddyTone = ValueNotifier('friendly'); // friendly | strict | motivational
final ValueNotifier<bool> dailyReminderOn = ValueNotifier(true);
final ValueNotifier<String> reminderTime = ValueNotifier('7:00 PM');
final ValueNotifier<bool> streakAlertOn = ValueNotifier(true);
final ValueNotifier<List<String>> weakSubjectsNotifier = ValueNotifier<List<String>>([]);

/// Inherited wrapper around [languageNotifier]. Placed once, high up,
/// via MaterialApp's `builder` — so it sits above the Navigator and
/// survives route pushes/pops untouched.
class AppLocale extends InheritedNotifier<ValueNotifier<String>> {
  const AppLocale({super.key, required ValueNotifier<String> notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static String of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppLocale>();
    return widget?.notifier?.value ?? 'en';
  }
}

/// Looks up [key] in the current language. Calling this inside a
/// widget's build method both fetches the string AND registers that
/// widget to rebuild whenever the language changes.
String tr(BuildContext context, String key) {
  final lang = AppLocale.of(context);
  return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
}

/// UI copy only — subject names and chapter titles are curriculum
/// content and belong in your backend/database, not this dictionary.
final Map<String, Map<String, String>> _strings = {
  // Onboarding
  'onb_skip': {'en': 'Skip', 'hi': 'छोड़ें'},
  'onb_next': {'en': 'Next', 'hi': 'आगे'},
  'onb_start': {'en': "Let's get started", 'hi': 'चलिए शुरू करें'},
  'onb1_title': {'en': 'Material made\nfor your class', 'hi': 'आपकी क्लास के\nलिए सामग्री'},
  'onb1_body': {
    'en': 'Pick Class 10 or 12 — notes, chapters and\npractice, all matched to your syllabus.',
    'hi': 'क्लास 10 या 12 चुनें — नोट्स, चैप्टर और\nप्रैक्टिस, सब आपके सिलेबस के अनुसार।',
  },
  'onb2_title': {'en': 'A friend who\nactually mentors you', 'hi': 'एक दोस्त जो\nसच में मार्गदर्शन करे'},
  'onb2_body': {
    'en': "Buddy talks with you — what to study first, what's worth the most marks, and checks in daily.",
    'hi': 'बडी आपसे बात करता है — पहले क्या पढ़ें, किसमें सबसे ज़्यादा नंबर हैं, और रोज़ाना पूछता है।',
  },
  'onb3_title': {'en': 'Watch yourself\nlevel up', 'hi': 'खुद को\nआगे बढ़ते देखें'},
  'onb3_body': {
    'en': 'Weak spots, streaks, and progress for every\nsubject — all in one place, before exam day.',
    'hi': 'कमज़ोर विषय, स्ट्रीक और हर सब्जेक्ट की\nप्रोग्रेस — परीक्षा से पहले एक ही जगह।',
  },

  // Auth choice
  'auth_tagline': {'en': 'Your personal mentor for Class 10 & 12', 'hi': 'क्लास 10 और 12 के लिए आपका पर्सनल मेंटर'},
  'auth_login': {'en': 'Log in', 'hi': 'लॉग इन करें'},
  'auth_new': {'en': 'Create account', 'hi': 'खाता बनाएं'},

  // Login
  'login_welcome': {'en': 'Welcome back!', 'hi': 'वापसी पर स्वागत है!'},
  'login_sub': {'en': "Log in to pick up right where you left off.", 'hi': 'जहाँ छोड़ा था वहीं से जारी रखने के लिए लॉग इन करें।'},
  'login_title': {'en': 'Login', 'hi': 'लॉग इन'},
  'email_hint': {'en': 'Email address', 'hi': 'ईमेल पता'},
  'password_hint': {'en': 'Password', 'hi': 'पासवर्ड'},
  'forgot_password': {'en': 'Forgot password?', 'hi': 'पासवर्ड भूल गए?'},
  'or_continue_with': {'en': 'or continue with', 'hi': 'या इसके साथ जारी रखें'},
  'or_signup_with': {'en': 'or sign up with', 'hi': 'या इसके साथ साइन अप करें'},
  'google': {'en': 'Google', 'hi': 'Google'},
  'phone_otp': {'en': 'Phone OTP', 'hi': 'फ़ोन OTP'},
  'new_here': {'en': 'New here? ', 'hi': 'नए हैं? '},
  'create_account_link': {'en': 'Create an account', 'hi': 'खाता बनाएं'},
  'already_have_account': {'en': 'Already have an account? ', 'hi': 'पहले से खाता है? '},
  'login_link': {'en': 'Log in', 'hi': 'लॉग इन करें'},

  // Register
  'register_title': {'en': 'Create your account', 'hi': 'अपना खाता बनाएं'},
  'register_sub': {
    'en': "Let's set you up with the right material and a Buddy that knows your class.",
    'hi': 'सही सामग्री और आपकी क्लास जानने वाले बडी के साथ शुरुआत करते हैं।',
  },
  'pick_avatar': {'en': 'PICK YOUR AVATAR', 'hi': 'अपना अवतार चुनें'},
  'which_class': {'en': 'WHICH CLASS ARE YOU IN?', 'hi': 'आप किस क्लास में हैं?'},
  'weak_subjects': {'en': 'WHICH SUBJECTS NEED THE MOST HELP?', 'hi': 'किन विषयों में सबसे ज़्यादा मदद चाहिए?'},
  'weak_subjects_sub': {
    'en': "Buddy will prioritize these first — pick as many as apply",
    'hi': 'बडी इन्हें पहले प्राथमिकता देगा — जितने लागू हों उतने चुनें',
  },
  'your_details': {'en': 'Your details', 'hi': 'आपकी जानकारी'},
  'full_name_hint': {'en': 'Full name', 'hi': 'पूरा नाम'},
  'confirm_password_hint': {'en': 'Confirm password', 'hi': 'पासवर्ड की पुष्टि करें'},
  'create_account_btn': {'en': 'Create Student Profile', 'hi': 'छात्र प्रोफ़ाइल बनाएं'},

  // Phone OTP
  'verify_phone': {'en': 'Verify your phone', 'hi': 'अपना फ़ोन सत्यापित करें'},
  'enter_code': {'en': 'Enter the code', 'hi': 'कोड दर्ज करें'},
  'send_code': {'en': 'Send code', 'hi': 'कोड भेजें'},
  'verify_continue': {'en': 'Verify & continue', 'hi': 'सत्यापित करें और जारी रखें'},
  'resend': {'en': "Didn't get it? Resend", 'hi': 'कोड नहीं मिला? दोबारा भेजें'},

  // Home
  'greet_morning': {'en': 'Rise and shine', 'hi': 'सुप्रभात, उठो और जागो'},
  'greet_afternoon': {'en': 'Keep up the momentum', 'hi': 'लगे रहो'},
  'greet_evening': {'en': 'Great work today', 'hi': 'आज बहुत बढ़िया काम किया'},
  'greet_night': {'en': 'Winding down', 'hi': 'अब आराम करने का समय'},
  'greet_late': {'en': 'Burning the midnight oil', 'hi': 'देर रात तक मेहनत जारी है'},
  'board_exam_mode': {'en': 'Board exam mode on', 'hi': 'बोर्ड परीक्षा मोड चालू'},
  'class_label': {'en': 'Class', 'hi': 'कक्षा'},
  'todays_plan': {'en': "Today's plan", 'hi': 'आज की योजना'},
  'complete': {'en': 'complete', 'hi': 'पूर्ण'},
  'minutes_today': {'en': 'min today', 'hi': 'मिनट आज'},
  'chapters_left': {'en': 'chapters left', 'hi': 'चैप्टर बाकी'},
  'day_streak': {'en': 'day streak', 'hi': 'दिन की स्ट्रीक'},
  'nudge_title': {'en': 'Study Trigonometry first today', 'hi': 'आज पहले त्रिकोणमिति पढ़ें'},
  'nudge_sub': {
    'en': "It's worth the most marks — Buddy picked this for you",
    'hi': 'इसमें सबसे ज़्यादा नंबर हैं — बडी ने आपके लिए चुना है',
  },

  // Nav
  'nav_home': {'en': 'Home', 'hi': 'होम'},
  'nav_study': {'en': 'Study', 'hi': 'पढ़ाई'},
  'nav_buddy': {'en': 'Buddy', 'hi': 'बडी'},
  'nav_progress': {'en': 'Progress', 'hi': 'प्रगति'},

  // Study material
  'study_title': {'en': 'Study material', 'hi': 'अध्ययन सामग्री'},
  'study_sub': {'en': 'Sorted by what actually gets you marks.', 'hi': 'जो असल में नंबर दिलाए, वही ऊपर।'},

  // Progress
  'progress_title': {'en': 'Your progress', 'hi': 'आपकी प्रगति'},
  'progress_sub': {
    'en': 'The clearer things are before exams, the better.',
    'hi': 'परीक्षा से पहले जितना स्पष्ट, उतना बेहतर।',
  },
  'stat_streak': {'en': 'Day streak', 'hi': 'दिन की स्ट्रीक'},
  'stat_score': {'en': 'Avg. score', 'hi': 'औसत स्कोर'},
  'stat_weak': {'en': 'Weak spots', 'hi': 'कमज़ोर विषय'},
  'this_week': {'en': 'This week', 'hi': 'इस सप्ताह'},
  'subject_wise': {'en': 'Subject-wise', 'hi': 'विषय अनुसार'},
  'practice_first': {'en': 'Practice these first', 'hi': 'पहले इनका अभ्यास करें'},
  'practice_btn': {'en': 'Practice', 'hi': 'अभ्यास करें'},

  // Chat
  'buddy_mentor': {'en': 'Your mentor · online', 'hi': 'आपका मेंटर · ऑनलाइन'},
  'chat_input_hint': {'en': 'Type your question...', 'hi': 'अपना सवाल लिखें...'},
  'todays_plan_card': {'en': "TODAY'S PLAN", 'hi': 'आज की योजना'},
  'lets_start': {'en': "Let's start", 'hi': 'शुरू करें'},
  'later': {'en': 'Later', 'hi': 'बाद में'},

  // Settings — appearance
  'settings_title': {'en': 'Settings', 'hi': 'सेटिंग्स'},
  'dark_mode': {'en': 'Dark mode', 'hi': 'डार्क मोड'},
  'dark_mode_sub': {'en': 'Easier on the eyes at night', 'hi': 'रात में आँखों के लिए आरामदायक'},
  'app_language': {'en': 'App language', 'hi': 'ऐप की भाषा'},
  'app_language_sub': {'en': 'Changes text across the whole app', 'hi': 'पूरे ऐप का टेक्स्ट बदलता है'},
  'appearance': {'en': 'APPEARANCE', 'hi': 'रूप-रंग'},

  // Settings — profile
  'profile': {'en': 'PROFILE', 'hi': 'प्रोफ़ाइल'},
  'edit_profile': {'en': 'Edit profile', 'hi': 'प्रोफ़ाइल संपादित करें'},
  'edit_profile_title': {'en': 'Edit profile', 'hi': 'प्रोफ़ाइल संपादित करें'},
  'save': {'en': 'Save', 'hi': 'सेव करें'},
  'cancel': {'en': 'Cancel', 'hi': 'रद्द करें'},
  'logout': {'en': 'Log out', 'hi': 'लॉग आउट'},
  'logout_confirm_title': {'en': 'Log out?', 'hi': 'लॉग आउट करें?'},
  'logout_confirm_body': {
    'en': "You'll need to log in again to continue.",
    'hi': 'जारी रखने के लिए आपको फिर से लॉग इन करना होगा।',
  },

  // Settings — notifications
  'notifications': {'en': 'NOTIFICATIONS', 'hi': 'सूचनाएं'},
  'daily_reminder': {'en': 'Daily reminder', 'hi': 'रोज़ाना रिमाइंडर'},
  'daily_reminder_sub': {'en': 'Buddy nudges you to study', 'hi': 'बडी आपको पढ़ने के लिए याद दिलाता है'},
  'reminder_time': {'en': 'Reminder time', 'hi': 'रिमाइंडर का समय'},
  'streak_alert': {'en': 'Streak alerts', 'hi': 'स्ट्रीक अलर्ट'},
  'streak_alert_sub': {
    'en': "Get notified before you lose your streak",
    'hi': 'स्ट्रीक टूटने से पहले सूचना पाएं',
  },

  // Settings — study preferences
  'study_prefs': {'en': 'STUDY PREFERENCES', 'hi': 'अध्ययन प्राथमिकताएं'},
  'daily_goal': {'en': 'Daily study goal', 'hi': 'दैनिक अध्ययन लक्ष्य'},
  'min_per_day': {'en': 'min / day', 'hi': 'मिनट / दिन'},
  'buddy_tone': {'en': "Buddy's tone", 'hi': 'बडी का अंदाज़'},
  'tone_friendly': {'en': 'Friendly', 'hi': 'दोस्ताना'},
  'tone_strict': {'en': 'Strict', 'hi': 'सख्त'},
  'tone_motivational': {'en': 'Motivational', 'hi': 'प्रेरक'},

  // Settings — about & help
  'about_help': {'en': 'ABOUT & HELP', 'hi': 'ऐप और सहायता'},
  'version': {'en': 'Version', 'hi': 'वर्शन'},
  'rate_app': {'en': 'Rate the app', 'hi': 'ऐप को रेट करें'},
  'send_feedback': {'en': 'Send feedback', 'hi': 'फीडबैक भेजें'},
  'contact_support': {'en': 'Contact support', 'hi': 'सहायता से संपर्क करें'},
  'terms_privacy': {'en': 'Terms & Privacy Policy', 'hi': 'नियम और गोपनीयता नीति'},
};
