import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import 'complete_quest_sheet.dart';
import 'task_editor_sheet.dart';

/// One quest row.
///
/// * [flat] drops the card chrome for embedding in a larger list card.
/// * [trailingCheckbox] puts the checkbox on the right and shows a category
///   icon tile on the left (the "Heute" layout from the mockup).
class QuestTile extends StatelessWidget {
  const QuestTile({
    super.key,
    required this.controller,
    required this.occurrence,
    this.flat = false,
    this.showDivider = false,
    this.trailingCheckbox = false,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;
  final bool flat;
  final bool showDivider;
  final bool trailingCheckbox;

  void _onTapBody(BuildContext context) {
    final canComplete = controller.canCompleteOn(occurrence.date);
    if (occurrence.isSkipped) {
      controller.unskipOccurrence(occurrence.id);
    } else if (occurrence.isCompleted) {
      if (canComplete) controller.undoComplete(occurrence.id);
    } else if (canComplete) {
      showCompleteQuestSheet(context, controller, occurrence);
    }
  }

  void _toggle(BuildContext context) {
    if (!controller.canCompleteOn(occurrence.date)) return;
    if (occurrence.isCompleted) {
      controller.undoComplete(occurrence.id);
    } else {
      controller.completeQuest(occurrence.id);
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

    final check = GestureDetector(
      onTap: () => _toggle(context),
      child: _Check(done: done, partial: partial, skipped: occurrence.isSkipped),
    );

    final row = InkWell(
      borderRadius: BorderRadius.circular(flat ? 10 : 16),
      onTap: () => _onTapBody(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(flat ? 4 : 14, 11, 6, 11),
        child: Row(
          children: [
            if (trailingCheckbox)
              _IconTile(icon: category.icon, color: category.color)
            else ...[
              check,
              const SizedBox(width: 12),
              Container(
                width: 3,
                height: 34,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: occurrence.isSkipped
                          ? TextDecoration.lineThrough
                          : null,
                      color: occurrence.isSkipped
                          ? AppTheme.textLow
                          : (done ? AppTheme.textMid : AppTheme.textHigh),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      if (occurrence.isRecurring && !trailingCheckbox) ...[
                        const Icon(Icons.autorenew,
                            size: 11, color: AppTheme.textLow),
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
                color:
                    occurrence.isSkipped ? AppTheme.textLow : AppTheme.goldBright,
              ),
            ),
            if (trailingCheckbox) ...[
              const SizedBox(width: 12),
              check,
              _QuestMenu(
                  controller: controller, occurrence: occurrence, subtle: true),
            ] else
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

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: color),
    );
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
  const _QuestMenu({
    required this.controller,
    required this.occurrence,
    this.subtle = false,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final isPast = controller.isPast(occurrence.date);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz,
          size: subtle ? 17 : 19, color: AppTheme.textLow),
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
