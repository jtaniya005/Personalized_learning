import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_settings.dart';
import '../widgets/notebook_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Dark mode ──
          NotebookCard(
            holeCount: 4,
            child: ValueListenableBuilder<bool>(
              valueListenable: isDarkNotifier,
              builder: (context, isDark, _) => Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.marigoldDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(context, 'dark_mode'),
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(tr(context, 'dark_mode_sub'),
                            style: Theme.of(context).textTheme.bodyMedium),
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
          const SizedBox(height: 16),

          // ── Language ──
          NotebookCard(
            holeCount: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.translate_rounded,
                          color: AppColors.teal, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(context, 'app_language'),
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(tr(context, 'app_language_sub'),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Segmented EN/HI switch — same interaction pattern as
                // the dark-mode switch above, just for two named options.
                ValueListenableBuilder<String>(
                  valueListenable: languageNotifier,
                  builder: (context, lang, _) => Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.rule),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LangOption(
                            label: 'English',
                            selected: lang == 'en',
                            onTap: () => languageNotifier.value = 'en',
                          ),
                        ),
                        Expanded(
                          child: _LangOption(
                            label: 'हिंदी',
                            selected: lang == 'hi',
                            onTap: () => languageNotifier.value = 'hi',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.marigold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? AppColors.ink : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
