import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/task_editor_sheet.dart';

enum _HabitFilter { alle, taeglich, woechentlich, einmalig, inaktiv }

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  _HabitFilter _filter = _HabitFilter.alle;

  MotivationController get controller => widget.controller;

  bool _isDaily(TaskDefinition d) =>
      d.recurrence.kind == RecurrenceKind.fixedWeekdays &&
      d.recurrence.weekdays.length == 7;

  bool _isWeekly(TaskDefinition d) =>
      d.recurrence.kind == RecurrenceKind.timesPerWeek ||
      (d.recurrence.kind == RecurrenceKind.fixedWeekdays &&
          d.recurrence.weekdays.length < 7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditorSheet(context, controller,
            date: controller.today, startAsRecurring: true),
        icon: const Icon(Icons.add),
        label: const Text(AppText.newRecurring),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final all = controller.definitions;
          final active = all.where((d) => !d.isArchived && !d.isPaused).toList();
          final inactive = all.where((d) => d.isArchived || d.isPaused).toList();
          final daily = active.where(_isDaily).toList();
          final weekly = active.where(_isWeekly).toList();
          final oneOffs = controller.upcomingOneOffs;

          final counts = {
            _HabitFilter.alle: active.length,
            _HabitFilter.taeglich: daily.length,
            _HabitFilter.woechentlich: weekly.length,
            _HabitFilter.einmalig: oneOffs.length,
            _HabitFilter.inaktiv: inactive.length,
          };

          List<Widget> rows() {
            switch (_filter) {
              case _HabitFilter.alle:
                return [
                  for (final d in active)
                    _HabitRow(controller: controller, definition: d),
                ];
              case _HabitFilter.taeglich:
                return [
                  for (final d in daily)
                    _HabitRow(controller: controller, definition: d),
                ];
              case _HabitFilter.woechentlich:
                return [
                  for (final d in weekly)
                    _HabitRow(controller: controller, definition: d),
                ];
              case _HabitFilter.inaktiv:
                return [
                  for (final d in inactive)
                    _HabitRow(controller: controller, definition: d),
                ];
              case _HabitFilter.einmalig:
                return [
                  for (final o in oneOffs)
                    _OneOffRow(controller: controller, occurrence: o),
                ];
            }
          }

          final list = rows();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppText.myHabits,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 26)),
                            const SizedBox(height: 2),
                            const Text(AppText.habitsSubline,
                                style: TextStyle(color: AppTheme.textMid)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in _labels.entries)
                        ChoiceChip(
                          label: Text('${entry.value} (${counts[entry.key]})'),
                          selected: _filter == entry.key,
                          onSelected: (_) =>
                              setState(() => _filter = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(AppText.noHabitsYet,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMid)),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < list.length; i++) ...[
                              list[i],
                              if (i < list.length - 1)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static const Map<_HabitFilter, String> _labels = {
    _HabitFilter.alle: AppText.filterAll,
    _HabitFilter.taeglich: AppText.filterDaily,
    _HabitFilter.woechentlich: AppText.filterWeekly,
    _HabitFilter.einmalig: AppText.filterOnce,
    _HabitFilter.inaktiv: AppText.filterInactive,
  };
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.controller, required this.definition});

  final MotivationController controller;
  final TaskDefinition definition;

  String _frequencyLabel() {
    final rule = definition.recurrence;
    if (rule.kind == RecurrenceKind.timesPerWeek) {
      return '${rule.timesPerWeek}× / Woche';
    }
    if (rule.weekdays.length == 7) return AppText.daily;
    return (rule.weekdays.toList()..sort())
        .map((w) => AppText.weekdayShort[w - 1])
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final category = controller.categoryById(definition.categoryId);
    final inactive = definition.isPaused || definition.isArchived;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(category.icon, size: 17, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(definition.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: inactive ? AppTheme.textMid : AppTheme.textHigh)),
                Text(category.name,
                    style: const TextStyle(
                        color: AppTheme.textLow, fontSize: 12)),
              ],
            ),
          ),
          Text('+${definition.xp} XP',
              style: const TextStyle(
                  color: AppTheme.goldBright, fontWeight: FontWeight.w700)),
          const SizedBox(width: 14),
          SizedBox(
            width: 88,
            child: Text(_frequencyLabel(),
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppTheme.textMid, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Switch(
            value: !inactive,
            onChanged: (on) => controller.editDefinition(
              definition.id,
              isPaused: !on,
              isArchived: false,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 18, color: AppTheme.textLow),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  showTaskEditorSheet(context, controller,
                      definition: definition);
                case 'archive':
                  controller.editDefinition(definition.id, isArchived: true);
                case 'delete':
                  controller.deleteDefinition(definition.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text(AppText.edit)),
              PopupMenuItem(value: 'archive', child: Text(AppText.archive)),
              PopupMenuItem(value: 'delete', child: Text(AppText.delete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OneOffRow extends StatelessWidget {
  const _OneOffRow({required this.controller, required this.occurrence});

  final MotivationController controller;
  final TaskOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final category = controller.categoryById(occurrence.categoryId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(category.icon, size: 17, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(occurrence.title,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(category.name,
                    style: const TextStyle(
                        color: AppTheme.textLow, fontSize: 12)),
              ],
            ),
          ),
          Text('+${occurrence.xp} XP',
              style: const TextStyle(
                  color: AppTheme.goldBright, fontWeight: FontWeight.w700)),
          const SizedBox(width: 14),
          SizedBox(
            width: 88,
            child: Text(
              '${AppText.once} · ${occurrence.date.day}.${occurrence.date.month}.',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 18, color: AppTheme.textLow),
            onSelected: (value) {
              if (value == 'edit') {
                showTaskEditorSheet(context, controller, existing: occurrence);
              } else if (value == 'delete') {
                controller.removeOccurrence(occurrence.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text(AppText.edit)),
              PopupMenuItem(value: 'delete', child: Text(AppText.delete)),
            ],
          ),
        ],
      ),
    );
  }
}
