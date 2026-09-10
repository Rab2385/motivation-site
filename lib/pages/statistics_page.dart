import 'package:flutter/material.dart';

import 'package:collection/collection.dart';

import '../domain/statistics.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.statistics,
      listenable: controller,
      builder: (context) {
        final theme = Theme.of(context);
        final stats = controller.statsSnapshot;
        final occurrences = controller.allOccurrences;
        final weekly = xpByWeek(occurrences);
        final rate = recentCompletionRate(occurrences, controller.today);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                _Kpi(label: 'XP', value: '${stats.totalXp}'),
                _Kpi(label: AppText.level, value: '${stats.level}'),
                _Kpi(label: AppText.quests, value: '${stats.totalCompletions}'),
              ],
            ),
            const SectionHeader('XP pro Woche'),
            _BarChart(
              values: {
                for (final entry in weekly)
                  entry.key.replaceAll('-W', ' KW '): entry.value,
              },
            ),
            const SectionHeader('XP pro Kategorie'),
            _BarChart(
              values: {
                for (final entry in stats.xpByCategory.entries)
                  controller.categoryById(entry.key).name: entry.value,
              },
              colorFor: (label) => controller.activeCategories
                  .where((c) => c.name == label)
                  .map((c) => c.color)
                  .firstOrNull,
            ),
            const SectionHeader('Erfolgsquote (30 Tage)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('${(rate * 100).round()} %',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: rate,
                          minHeight: 10,
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.successAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader('Diese Woche: geplant / erledigt'),
            _PlannedVsDone(controller: controller),
            const SectionHeader('Streaks'),
            for (final definition in controller.activeDefinitions)
              ListTile(
                dense: true,
                leading: Icon(
                  controller.categoryById(definition.categoryId).icon,
                  color: controller.categoryById(definition.categoryId).color,
                  size: 18,
                ),
                title: Text(definition.title),
                trailing: Text(
                  '${controller.streakFor(definition.id).current}'
                  '  ·  Best ${controller.streakFor(definition.id).best}',
                ),
              ),
          ],
        );
      },
    );
  }

}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, this.colorFor});

  final Map<String, int> values;
  final Color? Function(String label)? colorFor;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('Noch keine Daten.')),
      );
    }
    final maxValue = values.values.reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in values.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(entry.key,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: maxValue == 0 ? 0 : entry.value / maxValue,
                          minHeight: 14,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            colorFor?.call(entry.key) ?? AppTheme.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlannedVsDone extends StatelessWidget {
  const _PlannedVsDone({required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final days = controller.weekDays(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final day in days)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(AppText.weekdayShort[day.weekday - 1],
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Builder(builder: (context) {
                        final workload = controller.workloadForDate(day);
                        final planned = workload.plannedXp;
                        final done = workload.completedXp;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: planned == 0 ? 0 : done / planned,
                            minHeight: 12,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.successAccent),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.workloadForDate(day).completedXp}'
                      '/${controller.workloadForDate(day).plannedXp}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

