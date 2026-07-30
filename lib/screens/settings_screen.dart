import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';
import '../models/mock_data.dart';
import 'auth_choice_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int studentClass;
  final String studentName;
  final int avatarIndex;

  const SettingsScreen({
    super.key,
    required this.studentClass,
    required this.studentName,
    required this.avatarIndex,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int studentClass = widget.studentClass;
  late String studentName = widget.studentName;
  late int avatarIndex = widget.avatarIndex;

  void _returnProfile() {
    Navigator.of(context).pop({
      'name': studentName,
      'avatarIndex': avatarIndex,
      'studentClass': studentClass,
    });
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: studentName);
    int tempAvatar = avatarIndex;
    int tempClass = studentClass;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.rule,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(tr(sheetContext, 'edit_profile_title'),
                    style: Theme.of(sheetContext).textTheme.headlineMedium),
                const SizedBox(height: 18),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatarOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final a = avatarOptions[i];
                      final selected = tempAvatar == i;
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempAvatar = i),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: a.gradient),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? AppColors.ink : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(a.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: tr(sheetContext, 'full_name_hint'),
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [10, 12].map((c) {
                    final selected = tempClass == c;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => tempClass = c),
                        child: Container(
                          margin: EdgeInsets.only(right: c == 10 ? 12 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.marigold : AppColors.paperCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected ? AppColors.marigold : AppColors.rule),
                          ),
                          child: Text('Class $c',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: selected ? AppColors.ink : AppColors.inkSoft)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        studentName = nameController.text.trim().isEmpty
                            ? studentName
                            : nameController.text.trim();
                        avatarIndex = tempAvatar;
                        studentClass = tempClass;
                      });
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(tr(sheetContext, 'save')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(tr(dialogContext, 'logout_confirm_title'),
            style: Theme.of(dialogContext).textTheme.headlineMedium?.copyWith(fontSize: 20)),
        content: Text(tr(dialogContext, 'logout_confirm_body'),
            style: Theme.of(dialogContext).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr(dialogContext, 'cancel'),
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
                (route) => false,
              );
            },
            child: const Text('Log out', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = avatarOptions[avatarIndex % avatarOptions.length];

    return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, 'settings_title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _returnProfile,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            // ── Profile ──
            Text(tr(context, 'profile'), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 10),
            NotebookCard(
              holeCount: 4,
              onTap: _editProfile,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: avatar.gradient),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(avatar.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName, style: Theme.of(context).textTheme.titleMedium),
                        Text('${tr(context, 'class_label')} $studentClass',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.marigold.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tr(context, 'edit_profile'),
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.marigoldDeep)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── Appearance ──
            Text(tr(context, 'appearance'), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 10),
            NotebookCard(
              holeCount: 4,
              child: ValueListenableBuilder<bool>(
                valueListenable: isDarkNotifier,
                builder: (context, isDark, _) => Row(
                  children: [
                    _SettingIcon(
                        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.marigoldDeep,
                        bg: AppColors.ink.withOpacity(0.08)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(context, 'dark_mode'), style: Theme.of(context).textTheme.titleMedium),
                          Text(tr(context, 'dark_mode_sub'), style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeColor: AppColors.marigold,
                      onChanged: (v) => isDarkNotifier.value = v,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            NotebookCard(
              holeCount: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SettingIcon(
                          icon: Icons.translate_rounded,
                          color: AppColors.teal,
                          bg: AppColors.teal.withOpacity(0.14)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(context, 'app_language'), style: Theme.of(context).textTheme.titleMedium),
                            Text(tr(context, 'app_language_sub'), style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: languageNotifier,
                    builder: (context, lang, _) => _SegmentToggle(
                      options: const [('en', 'English'), ('hi', 'हिंदी')],
                      value: lang,
                      onChanged: (v) => languageNotifier.value = v,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── Notifications ──
            Text(tr(context, 'notifications'), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 10),
            NotebookCard(
              holeCount: 4,
              child: ValueListenableBuilder<bool>(
                valueListenable: dailyReminderOn,
                builder: (context, on, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SettingIcon(
                            icon: Icons.notifications_active_rounded,
                            color: AppColors.coral,
                            bg: AppColors.coral.withOpacity(0.14)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr(context, 'daily_reminder'), style: Theme.of(context).textTheme.titleMedium),
                              Text(tr(context, 'daily_reminder_sub'), style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        Switch(
                          value: on,
                          activeColor: AppColors.marigold,
                          onChanged: (v) => dailyReminderOn.value = v,
                        ),
                      ],
                    ),
                    if (on) ...[
                      const SizedBox(height: 12),
                      const DashedRule(),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: reminderTime,
                        builder: (context, time, _) => GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 19, minute: 0),
                            );
                            if (picked != null) {
                              reminderTime.value = picked.format(context);
                            }
                          },
                          child: Row(
                            children: [
                              Text(tr(context, 'reminder_time'), style: Theme.of(context).textTheme.bodyLarge),
                              const Spacer(),
                              Text(time,
                                  style: const TextStyle(
                                      color: AppColors.marigoldDeep, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkSoft),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            NotebookCard(
              holeCount: 4,
              child: ValueListenableBuilder<bool>(
                valueListenable: streakAlertOn,
                builder: (context, on, _) => Row(
                  children: [
                    _SettingIcon(
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.marigoldDeep,
                        bg: AppColors.marigold.withOpacity(0.16)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(context, 'streak_alert'), style: Theme.of(context).textTheme.titleMedium),
                          Text(tr(context, 'streak_alert_sub'), style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Switch(
                      value: on,
                      activeColor: AppColors.marigold,
                      onChanged: (v) => streakAlertOn.value = v,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ── Study preferences ──
            Text(tr(context, 'study_prefs'), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 10),
            NotebookCard(
              holeCount: 4,
              child: ValueListenableBuilder<int>(
                valueListenable: dailyGoalMinutes,
                builder: (context, minutes, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, 'daily_goal'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _StepButton(
                          icon: Icons.remove_rounded,
                          onTap: minutes > 10
                              ? () => dailyGoalMinutes.value = minutes - 10
                              : null,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('$minutes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(fontSize: 28, color: AppColors.marigoldDeep)),
                              Text(tr(context, 'min_per_day'), style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                        _StepButton(
                          icon: Icons.add_rounded,
                          onTap: minutes < 180
                              ? () => dailyGoalMinutes.value = minutes + 10
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            NotebookCard(
              holeCount: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, 'buddy_tone'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: buddyTone,
                    builder: (context, tone, _) => _SegmentToggle(
                      options: [
                        ('friendly', tr(context, 'tone_friendly')),
                        ('strict', tr(context, 'tone_strict')),
                        ('motivational', tr(context, 'tone_motivational')),
                      ],
                      value: tone,
                      onChanged: (v) => buddyTone.value = v,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── About & Help ──
            Text(tr(context, 'about_help'), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 10),
            NotebookCard(
              holeCount: 5,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 18),
              child: Column(
                children: [
                  _ListRow(icon: Icons.star_outline_rounded, label: tr(context, 'rate_app'), onTap: () {}),
                  const DashedRule(),
                  _ListRow(icon: Icons.chat_bubble_outline_rounded, label: tr(context, 'send_feedback'), onTap: () {}),
                  const DashedRule(),
                  _ListRow(icon: Icons.support_agent_rounded, label: tr(context, 'contact_support'), onTap: () {}),
                  const DashedRule(),
                  _ListRow(icon: Icons.description_outlined, label: tr(context, 'terms_privacy'), onTap: () {}),
                  const DashedRule(),
                  _ListRow(
                    icon: Icons.info_outline_rounded,
                    label: tr(context, 'version'),
                    trailing: '1.0.0',
                    showChevron: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.coral),
                label: Text(tr(context, 'logout'),
                    style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.coral),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  const _SettingIcon({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.rule.withOpacity(0.4) : AppColors.paper,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.rule),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? AppColors.inkSoft : AppColors.ink),
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _SegmentToggle({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rule),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = value == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.marigold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  opt.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: selected ? AppColors.ink : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _ListRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.inkSoft),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            if (trailing != null)
              Text(trailing!, style: Theme.of(context).textTheme.bodyMedium),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkSoft),
            ],
          ],
        ),
      ),
    );
  }
}
