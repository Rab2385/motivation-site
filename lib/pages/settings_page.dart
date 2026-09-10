import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/progression.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/category_editor_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _tab = 1;

  MotivationController get controller => widget.controller;

  static const _tabs = [
    AppText.tabGeneral,
    AppText.tabGamification,
    AppText.tabAppearance,
    AppText.tabData,
    AppText.tabAbout,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                Text(AppText.settings,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 26)),
                const SizedBox(height: 2),
                const Text(AppText.settingsSubline,
                    style: TextStyle(color: AppTheme.textMid)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      ChoiceChip(
                        label: Text(_tabs[i]),
                        selected: _tab == i,
                        onSelected: (_) => setState(() => _tab = i),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                switch (_tab) {
                  0 => _GeneralTab(controller: controller),
                  1 => _GamificationTab(controller: controller),
                  2 => _AppearanceTab(controller: controller),
                  3 => _DataTab(controller: controller),
                  _ => const _AboutTab(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Reusable bits ---------------------------------------------------------

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.textLow,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.hint, required this.trailing});
  final String title;
  final String? hint;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textHigh, fontWeight: FontWeight.w600)),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(hint!,
                        style: const TextStyle(
                            color: AppTheme.textMid, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.onDec,
    required this.onInc,
  });

  final String label;
  final VoidCallback? onDec;
  final VoidCallback? onInc;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDec,
            icon: const Icon(Icons.remove, size: 16),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textHigh, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onInc,
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }
}

// ---- Tabs -----------------------------------------------------------------

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Group(
          title: AppText.dayTargets,
          children: [
            for (var index = 0; index < 7; index++)
              _TargetRow(controller: controller, weekdayIndex: index),
          ],
        ),
        const _Group(
          title: 'Woche',
          children: [
            _Row(
              title: 'Wochenstart',
              hint: 'Die Woche beginnt am Montag.',
              trailing: Text('Montag', style: TextStyle(color: AppTheme.textMid)),
            ),
            _Row(
              title: 'Sprache',
              hint: 'Weitere Sprachen folgen.',
              trailing: Text('Deutsch', style: TextStyle(color: AppTheme.textMid)),
            ),
          ],
        ),
      ],
    );
  }
}

class _GamificationTab extends StatelessWidget {
  const _GamificationTab({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final mult = controller.xpMultiplier;
    final bonus = controller.perfectDayBonus;
    final time = controller.reminderTime;

    return Column(
      children: [
        _Group(
          title: AppText.xpAndLeveling,
          children: [
            _Row(
              title: AppText.xpMultiplier,
              hint: AppText.xpMultiplierHint,
              trailing: _Stepper(
                label: mult.toStringAsFixed(1),
                onDec: mult > 0.1
                    ? () => controller.setXpMultiplier(mult - 0.1)
                    : null,
                onInc: mult < 5.0
                    ? () => controller.setXpMultiplier(mult + 0.1)
                    : null,
              ),
            ),
            const Divider(height: 1),
            _Row(
              title: AppText.levelCurveLabel,
              hint: AppText.levelCurveHint,
              trailing: DropdownButton<LevelCurve>(
                value: controller.levelCurve,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.card,
                items: [
                  for (final c in LevelCurve.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (c) {
                  if (c != null) controller.setLevelCurve(c);
                },
              ),
            ),
            const Divider(height: 1),
            _Row(
              title: AppText.perfectDayBonusLabel,
              hint: AppText.perfectDayBonusHint,
              trailing: _Stepper(
                label: '+$bonus XP',
                onDec: bonus > 0
                    ? () => controller.setPerfectDayBonus(bonus - 10)
                    : null,
                onInc: bonus < 500
                    ? () => controller.setPerfectDayBonus(bonus + 10)
                    : null,
              ),
            ),
            const Divider(height: 1),
            _Row(
              title: AppText.streakProtectionLabel,
              hint: AppText.streakProtectionHint,
              trailing: Switch(
                value: controller.streakProtection,
                onChanged: controller.setStreakProtection,
              ),
            ),
          ],
        ),
        _Group(
          title: AppText.notifications,
          children: [
            _Row(
              title: AppText.dailyReminderLabel,
              hint: AppText.dailyReminderHint,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.dailyReminder)
                    _Stepper(
                      label: time,
                      onDec: () =>
                          controller.setReminderTime(_shiftTime(time, -30)),
                      onInc: () =>
                          controller.setReminderTime(_shiftTime(time, 30)),
                    ),
                  const SizedBox(width: 8),
                  Switch(
                    value: controller.dailyReminder,
                    onChanged: controller.setDailyReminder,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _Row(
              title: AppText.motivationMessagesLabel,
              hint: AppText.motivationMessagesHint,
              trailing: Switch(
                value: controller.motivationMessages,
                onChanged: controller.setMotivationMessages,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, top: 2),
              child: Text(AppText.notificationsUnavailable,
                  style: TextStyle(color: AppTheme.textLow, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }

  String _shiftTime(String hhmm, int deltaMinutes) {
    final parts = hhmm.split(':');
    var total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + deltaMinutes;
    total = (total + 1440) % 1440;
    final h = (total ~/ 60).toString().padLeft(2, '0');
    final m = (total % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AppearanceTab extends StatelessWidget {
  const _AppearanceTab({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return _Group(
      title: AppText.tabAppearance,
      children: [
        _Row(
          title: AppText.showAtmosphereLabel,
          hint: AppText.showAtmosphereHint,
          trailing: Switch(
            value: controller.showAtmosphere,
            onChanged: controller.setShowAtmosphere,
          ),
        ),
        const _Row(
          title: AppText.darkMode,
          hint: 'Quest ist bewusst nur in Dunkel gehalten.',
          trailing: Switch(value: true, onChanged: null),
        ),
      ],
    );
  }
}

class _DataTab extends StatelessWidget {
  const _DataTab({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Group(
          title: AppText.categoriesTitle,
          children: [
            for (final category in controller.categories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(category.name)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      onPressed: () => showCategoryEditorSheet(context,
                          controller, existing: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 17),
                      onPressed: () =>
                          controller.deleteCategory(category.id),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    showCategoryEditorSheet(context, controller),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(AppText.add),
              ),
            ),
          ],
        ),
        _Group(
          title: AppText.backup,
          children: [
            _Row(
              title: AppText.exportBackup,
              hint: 'Als JSON kopieren – lokale Daten können vom Browser gelöscht werden.',
              trailing: OutlinedButton(
                onPressed: () => _export(context),
                child: const Text('Export'),
              ),
            ),
            const Divider(height: 1),
            _Row(
              title: AppText.importBackup,
              hint: 'Ersetzt alle vorhandenen Daten.',
              trailing: OutlinedButton(
                onPressed: () => _import(context),
                child: const Text('Import'),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => _clear(context),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text(AppText.clearData),
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final json = await controller.exportBackupJson();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.exportBackup),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: SelectableText(json,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(context);
            },
            child: const Text('Kopieren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.close),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final textController = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.importBackup),
        content: TextField(
          controller: textController,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Backup-JSON einfügen …'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text(AppText.importBackup),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;
    try {
      await controller.importBackupJson(raw);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup importiert.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import fehlgeschlagen: $error')),
        );
      }
    }
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.clearData),
        content: const Text(AppText.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppText.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppText.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearAllData();
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return _Group(
      title: AppText.tabAbout,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppText.appName} — ${AppText.appTagline}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              const Text('Version 0.1.0',
                  style: TextStyle(color: AppTheme.textLow, fontSize: 12)),
              const SizedBox(height: 12),
              const Text(AppText.aboutText,
                  style: TextStyle(color: AppTheme.textMid, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.controller, required this.weekdayIndex});

  final MotivationController controller;
  final int weekdayIndex;

  @override
  Widget build(BuildContext context) {
    final value = controller.dayTargetXp[weekdayIndex];
    return Row(
      children: [
        SizedBox(width: 34, child: Text(AppText.weekdayShort[weekdayIndex])),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(0, 400),
            max: 400,
            divisions: 40,
            label: '$value',
            onChanged: (next) => controller.setDayTargetXp(
                weekdayIndex, (next / 10).round() * 10),
          ),
        ),
        SizedBox(width: 52, child: Text('$value XP',
            style: const TextStyle(color: AppTheme.textMid, fontSize: 12))),
      ],
    );
  }
}
