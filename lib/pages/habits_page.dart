import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/task_editor_sheet.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.habits,
      listenable: controller,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditorSheet(
          context,
          controller,
          date: controller.today,
          startAsRecurring: true,
        ),
        icon: const Icon(Icons.add),
        label: const Text(AppText.newRecurring),
      ),
      builder: (context) {
        final active = controller.definitions
            .where((d) => !d.isArchived)
            .toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        final archived =
            controller.definitions.where((d) => d.isArchived).toList();

        if (active.isEmpty && archived.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(AppText.noHabitsYet, textAlign: TextAlign.center),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            for (final definition in active)
              _HabitCard(controller: controller, definition: definition),
            if (archived.isNotEmpty) ...[
              const SectionHeader('Archiviert'),
              for (final definition in archived)
                _HabitCard(controller: controller, definition: definition),
            ],
          ],
        );
      },
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.controller, required this.definition});

  final MotivationController controller;
  final TaskDefinition definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = controller.categoryById(definition.categoryId);
    final streak = controller.streakFor(definition.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, color: category.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(definition.title,
                      style: theme.textTheme.titleMedium),
                ),
                if (definition.isPaused)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.pause_circle_outline, size: 18),
                  ),
                _menu(context),
              ],
            ),
            const SizedBox(height: 4),
            Text(_scheduleLabel(definition.recurrence),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                _Stat(
                  icon: Icons.local_fire_department,
                  color: AppTheme.streakAccent,
                  label: AppText.currentStreak,
                  value: '${streak.current}${streak.atRisk ? ' ⚠' : ''}',
                ),
                const SizedBox(width: 20),
                _Stat(
                  icon: Icons.emoji_events_outlined,
                  color: AppTheme.xpAccent,
                  label: AppText.bestStreak,
                  value: '${streak.best}',
                ),
                const SizedBox(width: 20),
                _Stat(
                  icon: Icons.bolt,
                  color: theme.colorScheme.primary,
                  label: AppText.xp,
                  value: '+${definition.xp}',
                ),
              ],
            ),
            if (streak.progressLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(streak.progressLabel, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            showTaskEditorSheet(context, controller, definition: definition);
          case 'pause':
            controller.editDefinition(definition.id, isPaused: true);
          case 'resume':
            controller.editDefinition(definition.id, isPaused: false);
          case 'archive':
            controller.editDefinition(definition.id, isArchived: true);
          case 'unarchive':
            controller.editDefinition(definition.id, isArchived: false);
          case 'delete':
            controller.deleteDefinition(definition.id);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text(AppText.edit)),
        if (!definition.isPaused && !definition.isArchived)
          const PopupMenuItem(value: 'pause', child: Text(AppText.pause)),
        if (definition.isPaused)
          const PopupMenuItem(value: 'resume', child: Text(AppText.resume)),
        if (!definition.isArchived)
          const PopupMenuItem(value: 'archive', child: Text(AppText.archive)),
        if (definition.isArchived)
          const PopupMenuItem(
              value: 'unarchive', child: Text(AppText.resume)),
        const PopupMenuItem(value: 'delete', child: Text(AppText.delete)),
      ],
    );
  }

  String _scheduleLabel(RecurrenceRule rule) {
    if (rule.kind == RecurrenceKind.timesPerWeek) {
      return '${rule.timesPerWeek} × pro Woche';
    }
    final days = (rule.weekdays.toList()..sort())
        .map((weekday) => AppText.weekdayShort[weekday - 1])
        .join(', ');
    return days.isEmpty ? '—' : days;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
