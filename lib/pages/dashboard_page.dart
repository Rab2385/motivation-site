import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/proposal_review_sheet.dart';
import '../widgets/quest_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.onOpenTab,
  });

  final MotivationController controller;
  final void Function(int index) onOpenTab;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.dashboard,
      listenable: controller,
      builder: (context) {
        final theme = Theme.of(context);
        final progress = controller.levelProgress;
        final quests = controller.todaysQuests;
        final openQuests = quests.where((q) => q.isOpen).toList();
        final workload = controller.workloadForDate(controller.today);
        final proposals = controller.pendingProposals;
        final streaks = [
          for (final definition in controller.activeDefinitions)
            (definition, controller.streakFor(definition.id)),
        ]..sort((a, b) => b.$2.current.compareTo(a.$2.current));
        final activeStreaks =
            streaks.where((entry) => entry.$2.current > 0).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (proposals.isNotEmpty)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text('${proposals.length} ${AppText.assistantProposal}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showProposalReviewSheet(
                      context, controller, proposals.first),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    LevelRing(progress: progress),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${progress.totalXp} XP',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          XpBar(progress: progress),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onOpenTab(1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(AppText.todaysProgress,
                              style: theme.textTheme.titleMedium),
                          const Spacer(),
                          Text(
                            '${quests.where((q) => q.isCompleted).length}'
                            ' / ${quests.length}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      WorkloadBar(workload: workload),
                      if (openQuests.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final quest in openQuests.take(3))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: QuestTile(
                                controller: controller, occurrence: quest),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (activeStreaks.isNotEmpty) ...[
              const SectionHeader(AppText.activeStreaks),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in activeStreaks)
                    Chip(
                      avatar: const Icon(Icons.local_fire_department,
                          size: 18, color: AppTheme.streakAccent),
                      label: Text('${entry.$1.title} · ${entry.$2.current}'),
                    ),
                ],
              ),
            ],
            const SectionHeader('Woche'),
            _WeekStrip(controller: controller, onOpen: () => onOpenTab(2)),
          ],
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.controller, required this.onOpen});

  final MotivationController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final days = controller.weekDays(0);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(AppText.weekdayShort[day.weekday - 1],
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        WorkloadBar(
                          workload: controller.workloadForDate(day),
                          showLabel: false,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.workloadForDate(day).plannedXp}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
