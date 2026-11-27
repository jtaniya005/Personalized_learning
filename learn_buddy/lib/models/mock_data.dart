import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Note: The Subject class and mockSubjects list have been removed.
// Subjects are now derived from the student's profile (class + stream)
// via subject_utils.dart — see buildSubjectList().

enum ChapterStatus { done, inProgress, locked }

class Chapter {
  final String title;
  final String tag;
  final Color tagColor;
  final String duration;
  final ChapterStatus status;

  const Chapter({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.duration,
    this.status = ChapterStatus.locked,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? audioBase64;
  final String? ttsProvider;
  final bool isVoice;
  final bool careerGrounded;
  final DateTime timestamp;

  ChatMessage(
    this.text,
    this.isUser, {
    this.audioBase64,
    this.ttsProvider,
    this.isVoice = false,
    this.careerGrounded = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DayActivity {
  final String label;
  final int minutes;
  final bool isToday;
  const DayActivity(this.label, this.minutes, {this.isToday = false});
}

class AvatarOption {
  final IconData icon;
  final List<Color> gradient;
  const AvatarOption(this.icon, this.gradient);
}

/// Picked at registration, shown across Home and Settings — icon-based,
/// not emoji, so they render identically across every device/OS.
final List<AvatarOption> avatarOptions = [
  AvatarOption(Icons.rocket_launch_rounded, [AppColors.marigold, AppColors.coral]),
  AvatarOption(Icons.emoji_events_rounded, [AppColors.coral, AppColors.marigoldDeep]),
  AvatarOption(Icons.auto_awesome_rounded, [AppColors.ink, AppColors.skyInk]),
  AvatarOption(Icons.psychology_rounded, [AppColors.teal, AppColors.skyInk]),
  AvatarOption(Icons.bolt_rounded, [AppColors.marigold, AppColors.teal]),
  AvatarOption(Icons.explore_rounded, [AppColors.coral, AppColors.grape]),
  AvatarOption(Icons.favorite_rounded, [AppColors.sage, AppColors.teal]),
  AvatarOption(Icons.school_rounded, [AppColors.grape, AppColors.coral]),
];

/// Mock weekly study activity — swap for real per-student data.
/// TODO: wire to /progress/weekly-activity when built
final List<DayActivity> mockWeekActivity = const [
  DayActivity('M', 25),
  DayActivity('T', 40),
  DayActivity('W', 15),
  DayActivity('T', 50),
  DayActivity('F', 30),
  DayActivity('S', 60),
  DayActivity('S', 20, isToday: true),
];
