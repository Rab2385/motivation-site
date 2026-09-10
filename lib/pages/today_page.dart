import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/quest_tile.dart';
import '../widgets/task_editor_sheet.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.today,
      listenable: controller,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditorSheet(
          context,
          controller,
          date: controller.today,
        ),
        icon: const Icon(Icons.add),
        label: const Text(AppText.newOneOff),
      ),
      builder: (context) {
        final quests = controller.todaysQuests;
        final workload = controller.workloadForDate(controller.today);
        final done = quests.where((q) => q.isCompleted).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_prettyDate(controller.today),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '$done / ${quests.length} ${AppText.quests}  ·  '
                            '${workload.completedXp} / ${workload.targetXp} XP',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (quests.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Icon(Icons.self_improvement,
                        size: 40, color: Theme.of(context).hintColor),
                    const SizedBox(height: 12),
                    const Text(AppText.noQuestsToday),
                    const SizedBox(height: 4),
                    Text(AppText.planYourWeek,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              )
            else
              for (final quest in quests)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: QuestTile(controller: controller, occurrence: quest),
                ),
          ],
        );
      },
    );
  }

  String _prettyDate(DateTime date) {
    final weekday = AppText.weekdayLong[date.weekday - 1];
    return '$weekday, ${date.day}.${date.month}.';
  }
}

String prettyShortDate(DateTime date) =>
    '${AppText.weekdayShort[date.weekday - 1]} ${date.day}.${date.month}.';
