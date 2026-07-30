import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Subject {
  final String name;
  final IconData icon;
  final Color color;
  final double progress; // 0..1
  final List<Chapter> chapters;

  const Subject({
    required this.name,
    required this.icon,
    required this.color,
    required this.progress,
    required this.chapters,
  });
}

class Chapter {
  final String title;
  final String tag; // e.g. "Exam favourite", "Weak area", "Quick revise"
  final Color tagColor;
  final String duration;

  const Chapter({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.duration,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage(this.text, this.isUser);
}

class DayActivity {
  final String label;
  final int minutes;
  final bool isToday;
  const DayActivity(this.label, this.minutes, {this.isToday = false});
}

class AvatarOption {
  final String emoji;
  final List<Color> gradient;
  const AvatarOption(this.emoji, this.gradient);
}

/// Picked at registration, shown across Home and Chat.
const List<AvatarOption> avatarOptions = [
  AvatarOption('😊', [AppColors.marigold, AppColors.coral]),
  AvatarOption('🦁', [AppColors.coral, AppColors.marigoldDeep]),
  AvatarOption('🐼', [AppColors.ink, AppColors.skyInk]),
  AvatarOption('🚀', [AppColors.teal, AppColors.skyInk]),
  AvatarOption('🌟', [AppColors.marigold, AppColors.teal]),
  AvatarOption('🦊', [AppColors.coral, AppColors.grape]),
  AvatarOption('🐨', [AppColors.sage, AppColors.teal]),
  AvatarOption('🎯', [AppColors.grape, AppColors.coral]),
];

/// Mock weekly study activity — swap for real per-student data.
final List<DayActivity> mockWeekActivity = const [
  DayActivity('M', 25),
  DayActivity('T', 40),
  DayActivity('W', 15),
  DayActivity('T', 50),
  DayActivity('F', 30),
  DayActivity('S', 60),
  DayActivity('S', 20, isToday: true),
];

/// Mock dataset for Class 10 — swap for API/RAG response later.
final List<Subject> mockSubjects = [
  Subject(
    name: 'Mathematics',
    icon: Icons.functions_rounded,
    color: AppColors.coral,
    progress: 0.62,
    chapters: [
      Chapter(
          title: 'Quadratic Equations',
          tag: 'Exam favourite',
          tagColor: AppColors.marigoldDeep,
          duration: '45 min'),
      Chapter(
          title: 'Trigonometry Basics',
          tag: 'Weak area',
          tagColor: AppColors.coral,
          duration: '30 min'),
      Chapter(
          title: 'Pair of Linear Equations',
          tag: 'Quick revise',
          tagColor: AppColors.sage,
          duration: '20 min'),
    ],
  ),
  Subject(
    name: 'Science',
    icon: Icons.science_rounded,
    color: AppColors.sage,
    progress: 0.40,
    chapters: [
      Chapter(
          title: 'Chemical Reactions',
          tag: 'Exam favourite',
          tagColor: AppColors.marigoldDeep,
          duration: '35 min'),
      Chapter(
          title: 'Light — Reflection & Refraction',
          tag: 'Weak area',
          tagColor: AppColors.coral,
          duration: '40 min'),
    ],
  ),
  Subject(
    name: 'Social Science',
    icon: Icons.public_rounded,
    color: AppColors.skyInk,
    progress: 0.78,
    chapters: [
      Chapter(
          title: 'Nationalism in India',
          tag: 'Quick revise',
          tagColor: AppColors.sage,
          duration: '25 min'),
      Chapter(
          title: 'Federalism',
          tag: 'Exam favourite',
          tagColor: AppColors.marigoldDeep,
          duration: '30 min'),
    ],
  ),
  Subject(
    name: 'English',
    icon: Icons.menu_book_rounded,
    color: AppColors.marigoldDeep,
    progress: 0.85,
    chapters: [
      Chapter(
          title: 'A Letter to God',
          tag: 'Quick revise',
          tagColor: AppColors.sage,
          duration: '15 min'),
    ],
  ),
];

/// Flattens every chapter tagged "Weak area" across all subjects,
/// paired with its parent subject for display on the Progress screen.
List<({Subject subject, Chapter chapter})> get mockWeakChapters {
  final result = <({Subject subject, Chapter chapter})>[];
  for (final s in mockSubjects) {
    for (final c in s.chapters) {
      if (c.tag == 'Weak area') {
        result.add((subject: s, chapter: c));
      }
    }
  }
  return result;
}
