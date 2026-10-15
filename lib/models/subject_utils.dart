import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Canonical subject list for a given class + stream combination.
/// Extracted from RegisterScreen so every screen derives subjects
/// from the same logic — no hardcoded subject lists anywhere else.
List<String> getSubjectsForClassAndStream(int studentClass, String? stream) {
  if (studentClass == 10) {
    return [
      'Mathematics',
      'Science',
      'Social Science',
      'English',
      'Hindi',
      'Computer Applications/IT',
    ];
  } else if (studentClass == 12 && stream != null) {
    if (stream == 'Science (PCM)') {
      return ['Physics', 'Chemistry', 'Mathematics', 'English'];
    } else if (stream == 'Science (PCB)') {
      return ['Physics', 'Chemistry', 'Biology', 'English'];
    } else if (stream == 'Commerce') {
      return ['Accountancy', 'Business Studies', 'Economics', 'English'];
    } else if (stream == 'Arts/Humanities') {
      return ['History', 'Political Science', 'Geography', 'Economics', 'English'];
    }
  }
  return [];
}

/// Icon for a subject name — used on Home cards, Study Material chips,
/// and Progress bars.  Matches the register screen's original mapping.
IconData getSubjectIcon(String subjectName) {
  switch (subjectName) {
    case 'Mathematics':
      return Icons.functions_rounded;
    case 'Science':
      return Icons.science_rounded;
    case 'Social Science':
      return Icons.public_rounded;
    case 'English':
      return Icons.menu_book_rounded;
    case 'Hindi':
      return Icons.translate_rounded;
    case 'Computer Applications/IT':
      return Icons.computer_rounded;
    case 'Physics':
      return Icons.biotech_rounded;
    case 'Chemistry':
      return Icons.science_rounded;
    case 'Biology':
      return Icons.eco_rounded;
    case 'Accountancy':
      return Icons.account_balance_wallet_rounded;
    case 'Business Studies':
      return Icons.business_center_rounded;
    case 'Economics':
      return Icons.trending_up_rounded;
    case 'History':
      return Icons.history_edu_rounded;
    case 'Political Science':
      return Icons.gavel_rounded;
    case 'Geography':
      return Icons.map_rounded;
    default:
      return Icons.book_rounded;
  }
}

/// Deterministic accent color for a subject — gives each card its own
/// identity without needing a backend "color" field.
Color getSubjectColor(String subjectName) {
  switch (subjectName) {
    case 'Mathematics':
      return AppColors.coral;
    case 'Science':
      return AppColors.sage;
    case 'Social Science':
      return AppColors.skyInk;
    case 'English':
      return AppColors.marigoldDeep;
    case 'Hindi':
      return AppColors.grape;
    case 'Computer Applications/IT':
      return AppColors.teal;
    case 'Physics':
      return AppColors.coral;
    case 'Chemistry':
      return AppColors.sage;
    case 'Biology':
      return AppColors.teal;
    case 'Accountancy':
      return AppColors.marigoldDeep;
    case 'Business Studies':
      return AppColors.skyInk;
    case 'Economics':
      return AppColors.grape;
    case 'History':
      return AppColors.coral;
    case 'Political Science':
      return AppColors.skyInk;
    case 'Geography':
      return AppColors.sage;
    default:
      return AppColors.marigold;
  }
}

/// Lightweight subject data holder used across Home, Study Material, and
/// Progress screens — replaces the old mock_data.dart Subject class.
class SubjectInfo {
  final String name;
  final IconData icon;
  final Color color;
  final double progress;  // 0..1  — 0 until progress module is built
  final bool isWeak;

  const SubjectInfo({
    required this.name,
    required this.icon,
    required this.color,
    this.progress = 0.0,
    this.isWeak = false,
  });
}

/// Build the full list of [SubjectInfo] for the current student,
/// sorted with weak subjects first.
List<SubjectInfo> buildSubjectList({
  required int studentClass,
  required String? stream,
  required List<String> weakSubjects,
}) {
  final names = getSubjectsForClassAndStream(studentClass, stream);
  final weakSet = weakSubjects.toSet();

  final subjects = names.map((name) {
    return SubjectInfo(
      name: name,
      icon: getSubjectIcon(name),
      color: getSubjectColor(name),
      progress: 0.0, // TODO: wire to real progress when progress module is built
      isWeak: weakSet.contains(name),
    );
  }).toList();

  // Weak subjects float to the top of the grid
  subjects.sort((a, b) {
    if (a.isWeak && !b.isWeak) return -1;
    if (!a.isWeak && b.isWeak) return 1;
    return 0;
  });

  return subjects;
}
