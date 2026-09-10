import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import 'complete_quest_sheet.dart';
import 'task_editor_sheet.dart';

/// One quest row. Tapping an open quest on the current day opens the complete
/// sheet; the trailing menu handles edit / skip / move / copy / remove.
///
/// [flat] drops the card chrome so the row can sit inside a larger list card
/// (the dashboard / today layout in the reference).
class QuestTile extends StatelessWidget {
  const QuestTile({
    super.key,
    required this.controller,
    required this.occurrence,
    this.flat = false,
    this.showDivider = false,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;
  final bool flat;
  final bool showDivider;

  void _onTap(BuildContext context) {
    final canComplete = controller.canCompleteOn(occurrence.date);
    if (occurrence.isSkipped) {
      controller.unskipOccurrence(occurrence.id);
    } else if (occurrence.isCompleted) {
      if (canComplete) controller.undoComplete(occurrence.id);
    } else if (canComplete) {
      showCompleteQuestSheet(context, controller, occurrence);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = controller.categoryById(occurrence.categoryId);
    final theme = Theme.of(context);
    final done = occurrence.isFullyCompleted;
    final partial = occurrence.isCompleted && !done;
    final subtitle = occurrence.note.trim().isNotEmpty
        ? occurrence.note.trim()
        : category.name;

    final row = InkWell(
      borderRadius: BorderRadius.circular(flat ? 10 : 16),
      onTap: () => _onTap(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(flat ? 4 : 14, 10, 4, 10),
        child: Row(
          children: [
            _Check(done: done, partial: partial, skipped: occurrence.isSkipped),
            const SizedBox(width: 12),
            Container(width: 3, height: 34, decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration:
                          occurrence.isSkipped ? TextDecoration.lineThrough : null,
                      color: occurrence.isSkipped
                          ? AppTheme.textLow
                          : (done ? AppTheme.textMid : AppTheme.textHigh),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      if (occurrence.isRecurring) ...[
                        const Icon(Icons.autorenew, size: 11, color: AppTheme.textLow),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          occurrence.isSkipped ? AppText.plannedSkip : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.quote.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${occurrence.isCompleted ? occurrence.completion!.awardedXp : occurrence.xp} XP',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: occurrence.isSkipped ? AppTheme.textLow : AppTheme.goldBright,
              ),
            ),
            _QuestMenu(controller: controller, occurrence: occurrence),
          ],
        ),
      ),
    );

    if (flat) {
      return Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.hairline)))
            : null,
        child: row,
      );
    }
    return Card(child: row);
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.partial, required this.skipped});

  final bool done;
  final bool partial;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    Color border = AppTheme.border;
    Color fill = Colors.transparent;
    Widget? mark;
    if (skipped) {
      mark = const Icon(Icons.remove, size: 15, color: AppTheme.textLow);
    } else if (done) {
      border = AppTheme.gold;
      fill = AppTheme.gold;
      mark = const Icon(Icons.check, size: 15, color: Color(0xFF231A05));
    } else if (partial) {
      border = AppTheme.gold;
      mark = const Icon(Icons.timelapse, size: 14, color: AppTheme.gold);
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border, width: 1.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: mark,
    );
  }
}

class _QuestMenu extends StatelessWidget {
  const _QuestMenu({required this.controller, required this.occurrence});

  final MotivationController controller;
  final TaskOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final isPast = controller.isPast(occurrence.date);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 19, color: AppTheme.textLow),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            showTaskEditorSheet(context, controller, existing: occurrence);
          case 'skip':
            controller.skipOccurrence(occurrence.id);
          case 'unskip':
            controller.unskipOccurrence(occurrence.id);
          case 'move':
            final date = await _pickDate(context, occurrence.date);
            if (date != null) controller.moveOccurrence(occurrence.id, date);
          case 'copy':
            final date = await _pickDate(context, occurrence.date);
            if (date != null) controller.copyOccurrence(occurrence.id, date);
          case 'remove':
            controller.removeOccurrence(occurrence.id);
        }
      },
      itemBuilder: (context) => [
        if (!isPast)
          const PopupMenuItem(value: 'edit', child: Text(AppText.edit)),
        if (!isPast && !occurrence.isSkipped && !occurrence.isCompleted)
          const PopupMenuItem(value: 'skip', child: Text(AppText.skip)),
        if (!isPast && occurrence.isSkipped)
          const PopupMenuItem(value: 'unskip', child: Text(AppText.undo)),
        if (!isPast)
          const PopupMenuItem(value: 'move', child: Text(AppText.move)),
        const PopupMenuItem(value: 'copy', child: Text(AppText.copy)),
        if (!isPast)
          const PopupMenuItem(value: 'remove', child: Text(AppText.delete)),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 28)),
      locale: const Locale('de'),
    );
  }
}
