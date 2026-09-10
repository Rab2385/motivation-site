import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_tile.dart';
import '../widgets/task_editor_sheet.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  DateTime _date = DateTime.now();

  MotivationController get controller => widget.controller;

  void _shift(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final today = controller.today;
    _date = DateTime(_date.year, _date.month, _date.day);
    final isToday = _date == today;
    final isPast = _date.isBefore(today);
    final canGoBack = _date.isAfter(today.subtract(const Duration(days: 14)));
    final canGoFwd = _date.isBefore(today.add(const Duration(days: 14)));

    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final quests = controller.occurrencesForDay(_date);
          final done = quests.where((q) => q.isCompleted).length;
          final earned = controller.completedXpForDate(_date) +
              controller.bonusXpForDate(_date);
          final possible = controller.possibleXpForDate(_date);
          final ratio = quests.isEmpty ? 0.0 : done / quests.length;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Heute',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 28)),
                            const SizedBox(height: 2),
                            const Text('Kleine Schritte. Große Veränderungen.',
                                style: TextStyle(color: AppTheme.textMid)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _DateNav(
                            label: isToday ? 'Heute' : prettyShortDate(_date),
                            onPrev: canGoBack ? () => _shift(-1) : null,
                            onNext: canGoFwd ? () => _shift(1) : null,
                            onReset: isToday
                                ? null
                                : () => setState(() => _date = today),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: isPast
                                ? null
                                : () => showTaskEditorSheet(context, controller,
                                    date: _date),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(AppText.addTask),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('$done von ${quests.length}${AppText.tasksDoneOf}',
                                  style: Theme.of(context).textTheme.titleSmall),
                              const Spacer(),
                              Text('${(ratio * 100).round()}%',
                                  style: const TextStyle(
                                      color: AppTheme.goldBright,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 9,
                              backgroundColor: const Color(0xFF1B2740),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.gold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${AppText.earnedToday}$earned XP / $possible${AppText.xpPossible}',
                            style: const TextStyle(
                                color: AppTheme.textMid, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (quests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: Column(
                        children: [
                          const Icon(Icons.self_improvement,
                              size: 38, color: AppTheme.textLow),
                          const SizedBox(height: 12),
                          Text(
                            isPast
                                ? 'Keine Aufgaben an diesem Tag.'
                                : AppText.noQuestsToday,
                            style: const TextStyle(color: AppTheme.textMid),
                          ),
                        ],
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < quests.length; i++)
                              QuestTile(
                                controller: controller,
                                occurrence: quests[i],
                                flat: true,
                                trailingCheckbox: true,
                                showDivider: i < quests.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (controller.motivationMessages) ...[
                    const SizedBox(height: 22),
                    Center(
                      child: Text('„${AppText.notPerfectJustConsistent}"',
                          style: AppTheme.quote),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateNav extends StatelessWidget {
  const _DateNav({
    required this.label,
    this.onPrev,
    this.onNext,
    this.onReset,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: AppText.previousDay,
          ),
          GestureDetector(
            onTap: onReset,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textHigh, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: AppText.nextDay,
          ),
        ],
      ),
    );
  }
}

String prettyShortDate(DateTime date) =>
    '${AppText.weekdayShort[date.weekday - 1]}, ${date.day}.${date.month}.';
