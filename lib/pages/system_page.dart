import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/backup_reminder.dart';
import '../domain/progression.dart';
import '../l10n/app_text.dart';
import '../services/backup_file.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/category_editor_sheet.dart';
import '../widgets/terminal_widgets.dart';

class SystemPage extends StatefulWidget {
  const SystemPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  int _tab = 1;

  MotivationController get controller => widget.controller;

  static const _tabs = [
    AppText.tabGeneral,
    AppText.tabGamification,
    AppText.tabData,
    AppText.tabAbout,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TerminalPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TerminalHeader(
                      'system',
                      comment: AppText.settingsSubline,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          _TabChip(
                            label: _tabs[i],
                            selected: _tab == i,
                            onTap: () => setState(() => _tab = i),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              switch (_tab) {
                0 => _GeneralTab(controller: controller),
                1 => _GamificationTab(controller: controller),
                2 => _DataTab(controller: controller),
                _ => const _AboutTab(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.amber.withValues(alpha: 0.18)
              : AppTheme.cardInset,
          border: Border.all(
            color: selected ? AppTheme.amber : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamilyFallback: AppTheme.mono,
            fontSize: 12,
            color: selected ? AppTheme.amberBright : AppTheme.textMid,
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TerminalPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalHeader(title),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, this.hint, required this.trailing});
  final String title;
  final String? hint;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    color: AppTheme.textHigh,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '// $hint',
                      style: AppTheme.comment.copyWith(fontSize: 11),
                    ),
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
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDec,
            icon: const Icon(Icons.remove, size: 15),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamilyFallback: AppTheme.mono,
                color: AppTheme.textHigh,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onInc,
            icon: const Icon(Icons.add, size: 15),
          ),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Group(
          title: AppText.profile,
          children: [
            _SettingRow(
              title: 'Name',
              hint: 'Used in the daily greeting',
              trailing: SizedBox(
                width: 220,
                child: TextFormField(
                  initialValue: controller.userName,
                  textAlign: TextAlign.end,
                  onChanged: controller.setUserName,
                  style: const TextStyle(
                    color: AppTheme.textHigh,
                    fontFamilyFallback: AppTheme.mono,
                    fontSize: 12.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
            _SettingRow(
              title: 'Birthday',
              hint: 'Birthday wishes show automatically',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.userBirthday ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now().add(
                          const Duration(days: 36500),
                        ),
                      );
                      if (picked != null) {
                        await controller.setUserBirthday(picked);
                      }
                    },
                    icon: const Icon(Icons.cake_rounded, size: 15),
                    label: Text(
                      controller.userBirthday == null
                          ? 'Add birthday'
                          : controller.birthdayLabel,
                    ),
                  ),
                  if (controller.userBirthday != null)
                    TextButton(
                      onPressed: () async => controller.setUserBirthday(null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ],
        ),
        _Group(
          title: AppText.notifications,
          children: [
            _SettingRow(
              title: AppText.dailyReminderLabel,
              hint: AppText.dailyReminderHint,
              trailing: Switch(
                value: controller.dailyReminder,
                onChanged: controller.setDailyReminder,
              ),
            ),
            _SettingRow(
              title: AppText.motivationMessagesLabel,
              hint: AppText.motivationMessagesHint,
              trailing: Switch(
                value: controller.motivationMessages,
                onChanged: controller.setMotivationMessages,
              ),
            ),
            _SettingRow(
              title: AppText.weeklyReviewDayLabel,
              hint: AppText.weeklyReviewDayHint,
              trailing: DropdownButton<int>(
                value: controller.weeklyReviewDay,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.card,
                items: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    DropdownMenuItem<int>(
                      value: day,
                      child: Text(AppText.weekdayLong[day - DateTime.monday]),
                    ),
                ],
                onChanged: (day) {
                  if (day != null) controller.setWeeklyReviewDay(day);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '// ${AppText.notificationsUnavailable}',
                style: TextStyle(color: AppTheme.textLow, fontSize: 10.5),
              ),
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
    final goal = controller.dailyGoalPercent;

    return Column(
      children: [
        _Group(
          title: AppText.xpAndLeveling,
          children: [
            _SettingRow(
              title: AppText.xpMultiplier,
              hint: AppText.xpMultiplierHint,
              trailing: _Stepper(
                label: 'x${mult.toStringAsFixed(1)}',
                onDec: mult > 0.1
                    ? () => controller.setXpMultiplier(mult - 0.1)
                    : null,
                onInc: mult < 5.0
                    ? () => controller.setXpMultiplier(mult + 0.1)
                    : null,
              ),
            ),
            _SettingRow(
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
            _SettingRow(
              title: AppText.perfectDayBonusLabel,
              hint: AppText.perfectDayBonusHint,
              trailing: _Stepper(
                label: '+$bonus',
                onDec: bonus > 0
                    ? () => controller.setPerfectDayBonus(bonus - 10)
                    : null,
                onInc: bonus < 500
                    ? () => controller.setPerfectDayBonus(bonus + 10)
                    : null,
              ),
            ),
            _SettingRow(
              title: AppText.streakProtectionLabel,
              hint: AppText.streakProtectionHint,
              trailing: Switch(
                value: controller.streakProtection,
                onChanged: controller.setStreakProtection,
              ),
            ),
            _SettingRow(
              title: AppText.dailyGoalLabel,
              hint: AppText.dailyGoalHint,
              trailing: _Stepper(
                label: '$goal%',
                onDec: goal > 5
                    ? () => controller.setDailyGoalPercent(goal - 5)
                    : null,
                onInc: goal < 100
                    ? () => controller.setDailyGoalPercent(goal + 5)
                    : null,
              ),
            ),
          ],
        ),
        _Group(
          title: AppText.dayTargets,
          children: [
            for (var i = 0; i < 7; i++)
              _TargetRow(controller: controller, weekdayIndex: i),
          ],
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
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontFamilyFallback: AppTheme.mono,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      onPressed: () => showCategoryEditorSheet(
                        context,
                        controller,
                        existing: category,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 15),
                      onPressed: () => controller.deleteCategory(category.id),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showCategoryEditorSheet(context, controller),
                icon: const Icon(Icons.add, size: 15),
                label: const Text(AppText.add),
              ),
            ),
          ],
        ),
        _Group(
          title: AppText.backup,
          children: [
            _SettingRow(
              title: AppText.downloadBackup,
              hint: AppText.backupDownloadHint,
              trailing: Wrap(
                spacing: 6,
                children: [
                  FilledButton(
                    onPressed: () => _download(context),
                    child: const Text('download'),
                  ),
                  OutlinedButton(
                    onPressed: () => _export(context),
                    child: const Text(AppText.copyBackupJson),
                  ),
                ],
              ),
            ),
            _SettingRow(
              title: AppText.lastBackupLabel,
              trailing: Text(
                controller.lastBackupAt == null
                    ? AppText.neverBackedUp
                    : _formatBackupTime(controller.lastBackupAt!),
                style: TextStyle(
                  fontFamilyFallback: AppTheme.mono,
                  fontSize: 12,
                  color: controller.lastBackupAt == null
                      ? AppTheme.amberBright
                      : AppTheme.textHigh,
                ),
              ),
            ),
            _SettingRow(
              title: AppText.backupReminderLabel,
              hint: AppText.backupReminderHint,
              trailing: DropdownButton<int>(
                value: backupReminderChoices.contains(
                  controller.backupReminderDays,
                )
                    ? controller.backupReminderDays
                    : defaultBackupReminderDays,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.card,
                items: [
                  for (final days in backupReminderChoices)
                    DropdownMenuItem<int>(
                      value: days,
                      child: Text(backupReminderLabel(days)),
                    ),
                ],
                onChanged: (days) {
                  if (days != null) controller.setBackupReminderDays(days);
                },
              ),
            ),
            if (kIsWeb) const _PersistentStorageRow(),
            _BackupSizeRow(controller: controller),
            _SettingRow(
              title: AppText.importBackup,
              hint: 'replaces all local data.',
              trailing: OutlinedButton(
                onPressed: () => _import(context),
                child: const Text('import'),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _clear(context),
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text(AppText.clearData),
          ),
        ),
      ],
    );
  }

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final location = await controller.downloadBackup();
      messenger.showSnackBar(
        SnackBar(content: Text('${AppText.backupSavedTo} $location')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('${AppText.backupFailed} $error')),
      );
    }
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
            child: SelectableText(
              json,
              style: const TextStyle(
                fontFamilyFallback: AppTheme.mono,
                fontSize: 11,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              controller.markBackedUp();
              Navigator.pop(context);
            },
            child: const Text('copy'),
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
          decoration: const InputDecoration(hintText: 'paste backup json …'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup imported.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $error')));
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppText.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearAllData();
  }
}

String _formatBackupTime(DateTime at) {
  final local = at.toLocal();
  final month = AppText.monthLong[local.month - 1].substring(0, 3).toLowerCase();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.day} $month ${local.year} $hh:$mm';
}

/// Web only: whether the browser promised not to evict the IndexedDB data,
/// with a button to ask for it.
class _PersistentStorageRow extends StatefulWidget {
  const _PersistentStorageRow();

  @override
  State<_PersistentStorageRow> createState() => _PersistentStorageRowState();
}

class _PersistentStorageRowState extends State<_PersistentStorageRow> {
  bool? _persistent;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    isStoragePersistent().then((value) {
      if (mounted) setState(() => _persistent = value);
    });
  }

  Future<void> _request() async {
    final granted = await requestPersistentStorage();
    if (mounted) {
      setState(() {
        _persistent = granted;
        _asked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (_persistent == true) {
      trailing = const Text(
        AppText.persistentStorageGranted,
        style: TextStyle(
          fontFamilyFallback: AppTheme.mono,
          fontSize: 12,
          color: AppTheme.successAccent,
        ),
      );
    } else if (_asked) {
      trailing = const Text(
        AppText.persistentStorageDenied,
        style: TextStyle(
          fontFamilyFallback: AppTheme.mono,
          fontSize: 12,
          color: AppTheme.amberBright,
        ),
      );
    } else {
      trailing = OutlinedButton(
        onPressed: _request,
        child: const Text(AppText.persistentStorageRequest),
      );
    }
    return _SettingRow(
      title: AppText.persistentStorageLabel,
      hint: AppText.persistentStorageHint,
      trailing: trailing,
    );
  }
}

/// Record count and backup size, computed from an export when the tab opens.
class _BackupSizeRow extends StatefulWidget {
  const _BackupSizeRow({required this.controller});

  final MotivationController controller;

  @override
  State<_BackupSizeRow> createState() => _BackupSizeRowState();
}

class _BackupSizeRowState extends State<_BackupSizeRow> {
  late final Future<String> _export = widget.controller.exportBackupJson();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _export,
      builder: (context, snapshot) {
        final json = snapshot.data;
        final String label;
        if (json == null) {
          label = '…';
        } else {
          final data = (jsonDecode(json) as Map)['data'] as Map;
          var records = 0;
          for (final value in data.values) {
            if (value is List) records += value.length;
            if (value is Map) records += value.length;
          }
          final kb = (utf8.encode(json).length / 1024).ceil();
          label = '$records · $kb KB';
        }
        return _SettingRow(
          title: AppText.backupSizeLabel,
          trailing: Text(
            label,
            style: const TextStyle(
              fontFamilyFallback: AppTheme.mono,
              fontSize: 12,
              color: AppTheme.textMid,
            ),
          ),
        );
      },
    );
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppText.appName} — ${AppText.appTagline}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              const Text(
                'v0.1.0',
                style: TextStyle(color: AppTheme.textLow, fontSize: 11),
              ),
              const SizedBox(height: 10),
              const Text(
                AppText.aboutText,
                style: TextStyle(color: AppTheme.textMid, height: 1.5),
              ),
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
        SizedBox(
          width: 34,
          child: Text(
            AppText.weekdayShort[weekdayIndex].toLowerCase(),
            style: const TextStyle(
              fontFamilyFallback: AppTheme.mono,
              fontSize: 11.5,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(0, 400),
            max: 400,
            divisions: 40,
            label: '$value',
            onChanged: (next) => controller.setDayTargetXp(
              weekdayIndex,
              (next / 10).round() * 10,
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '$value xp',
            style: const TextStyle(
              fontFamilyFallback: AppTheme.mono,
              color: AppTheme.textMid,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
