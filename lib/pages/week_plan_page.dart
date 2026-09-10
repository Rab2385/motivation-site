import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../widgets/attach_task_sheet.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/quest_tile.dart';
import '../widgets/task_editor_sheet.dart';

class WeekPlanPage extends StatefulWidget {
  const WeekPlanPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<WeekPlanPage> createState() => _WeekPlanPageState();
}

class _WeekPlanPageState extends State<WeekPlanPage> {
  int _weekOffset = 0;

  MotivationController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.weekPlanning,
      listenable: controller,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'save') _saveTemplate();
            if (value == 'apply') _applyTemplate();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'save', child: Text(AppText.saveAsTemplate)),
            if (controller.templates.isNotEmpty)
              const PopupMenuItem(
                  value: 'apply', child: Text(AppText.applyTemplate)),
          ],
        ),
      ],
      builder: (context) {
        final days = controller.weekDays(_weekOffset);
        final quotaDefs = controller.quotaDefinitions;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text(AppText.thisWeek)),
                ButtonSegment(value: 1, label: Text(AppText.nextWeek)),
              ],
              selected: {_weekOffset},
              onSelectionChanged: (value) =>
                  setState(() => _weekOffset = value.first),
            ),
            if (quotaDefs.isNotEmpty) ...[
              const SectionHeader(AppText.weeklyChips),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final definition in quotaDefs)
                    InputChip(
                      avatar: Icon(
                        controller.categoryById(definition.categoryId).icon,
                        size: 16,
                        color:
                            controller.categoryById(definition.categoryId).color,
                      ),
                      label: Text(
                        '${definition.title}  '
                        '${controller.quotaPlaced(definition.id, _weekOffset)}'
                        '/${definition.recurrence.timesPerWeek}',
                      ),
                      onPressed: () => _placeQuota(definition.id, days),
                    ),
                ],
              ),
            ],
            for (final day in days) _DaySection(
              controller: controller,
              date: day,
              onAdd: () => _addMenu(day),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMenu(DateTime day) async {
    final isPast = controller.isPast(day);
    if (isPast) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text(AppText.newOneOff),
              onTap: () => Navigator.pop(context, 'oneoff'),
            ),
            ListTile(
              leading: const Icon(Icons.autorenew),
              title: const Text(AppText.newRecurring),
              onTap: () => Navigator.pop(context, 'recurring'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text(AppText.attachExisting),
              onTap: () => Navigator.pop(context, 'attach'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'oneoff':
        showTaskEditorSheet(context, controller, date: day);
      case 'recurring':
        showTaskEditorSheet(context, controller,
            date: day, startAsRecurring: true);
      case 'attach':
        showAttachTaskSheet(context, controller, day);
    }
  }

  Future<void> _placeQuota(String definitionId, List<DateTime> days) async {
    final selectable = days.where((d) => !controller.isPast(d)).toList();
    final chosen = await showDialog<DateTime>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('An welchem Tag?'),
        children: [
          for (final day in selectable)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, day),
              child: Text(AppText.weekdayLong[day.weekday - 1]),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await controller.placeQuotaOccurrence(
        definitionId: definitionId, date: chosen);
  }

  Future<void> _saveTemplate() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppText.saveAsTemplate),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: AppText.templateName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppText.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text(AppText.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await controller.saveWeekAsTemplate(name: name, weekOffset: _weekOffset);
  }

  Future<void> _applyTemplate() async {
    final template = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppText.applyTemplate),
        children: [
          for (final template in controller.templates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, template.id),
              child: Text('${template.name} (${template.entries.length})'),
            ),
        ],
      ),
    );
    if (template == null) return;
    final result = await controller.applyTemplate(
      templateId: template,
      weekOffset: _weekOffset,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.added} hinzugefügt, ${result.skipped} bereits vorhanden',
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.controller,
    required this.date,
    required this.onAdd,
  });

  final MotivationController controller;
  final DateTime date;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quests = controller.occurrencesForDay(date);
    final workload = controller.workloadForDate(date);
    final hint = controller.overloadHintFor(date);
    final isToday = controller.canCompleteOn(date);
    final isPast = controller.isPast(date);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppText.weekdayLong[date.weekday - 1],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isToday ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(width: 8),
              Text('${date.day}.${date.month}.',
                  style: theme.textTheme.bodySmall),
              const Spacer(),
              if (!isPast)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 4),
            child: WorkloadBar(workload: workload),
          ),
          if (hint != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint.lightestDay == null
                            ? AppText.dayLooksHeavy
                            : '${AppText.dayLooksHeavy} '
                                '${AppText.moveSomethingTo}'
                                '${AppText.weekdayLong[hint.lightestDay!.weekday - 1]}?',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => controller.dismissOverloadHint(date),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
          if (quests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('—', style: theme.textTheme.bodySmall),
            )
          else
            for (final quest in quests)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: QuestTile(controller: controller, occurrence: quest),
              ),
        ],
      ),
    );
  }
}
