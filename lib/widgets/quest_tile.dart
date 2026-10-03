import 'package:flutter/material.dart';

import '../domain/habit_target.dart';
import '../l10n/app_text.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import 'complete_quest_sheet.dart';
import 'log_progress_sheet.dart';
import 'task_editor_sheet.dart';

/// One habit/task row: `[ ] icon Title            🔥N  +XP  ⋯`, with a
/// `// note` or quantity-progress line underneath.
///
/// [flat] drops the card chrome for embedding in a larger list card.
class QuestTile extends StatelessWidget {
  const QuestTile({
    super.key,
    required this.controller,
    required this.occurrence,
    this.flat = false,
    this.showDivider = false,
    this.showStreak = false,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;
  final bool flat;
  final bool showDivider;
  final bool showStreak;

  void _onTapCheckbox(BuildContext context) {
    if (!controller.canCompleteOn(occurrence.date)) return;
    if (occurrence.isSkipped) {
      controller.unskipOccurrence(occurrence.id);
      return;
    }
    if (occurrence.hasTarget) {
      showLogProgressSheet(context, controller, occurrence);
      return;
    }
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
    final streak =
        showStreak &&
            occurrence.isRecurring &&
            occurrence.sourceDefinitionId != null
        ? controller.streakFor(occurrence.sourceDefinitionId!).current
        : 0;

    String subtitle;
    if (occurrence.isSkipped) {
      subtitle = AppText.plannedSkip;
    } else if (occurrence.hasTarget) {
      subtitle = formatTargetProgress(
        occurrence.loggedAmount,
        occurrence.target!,
      );
    } else if (occurrence.note.trim().isNotEmpty) {
      subtitle = occurrence.note.trim();
    } else {
      subtitle = category.name;
    }

    final row = InkWell(
      borderRadius: BorderRadius.circular(flat ? 6 : 10),
      onTap: () => _onTapCheckbox(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(flat ? 4 : 12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _Bracket(
                done: done,
                partial: partial,
                skipped: occurrence.isSkipped,
              ),
            ),
            const SizedBox(width: 8),
            Icon(category.icon, size: 15, color: category.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 13.5,
                      height: 1.25,
                      decoration: occurrence.isSkipped
                          ? TextDecoration.lineThrough
                          : null,
                      color: occurrence.isSkipped
                          ? AppTheme.textLow
                          : (done ? AppTheme.textMid : AppTheme.textHigh),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: AppTheme.comment.copyWith(fontSize: 10.5),
                    ),
                ],
              ),
            ),
            if (streak > 0) ...[
              const Icon(
                Icons.local_fire_department,
                size: 12,
                color: AppTheme.streakAccent,
              ),
              const SizedBox(width: 2),
              Text(
                '$streak',
                style: const TextStyle(
                  color: AppTheme.streakAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '+${occurrence.isCompleted ? occurrence.completion!.awardedXp : occurrence.xp}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: occurrence.isSkipped
                    ? AppTheme.textLow
                    : AppTheme.amberBright,
              ),
            ),
            const SizedBox(width: 4),
            _QuestMenu(controller: controller, occurrence: occurrence),
          ],
        ),
      ),
    );

    if (flat) {
      return Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.hairline)),
              )
            : null,
        child: row,
      );
    }
    return Card(child: row);
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({
    required this.done,
    required this.partial,
    required this.skipped,
  });

  final bool done;
  final bool partial;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final String mark;
    final Color color;
    if (skipped) {
      mark = '[-]';
      color = AppTheme.textLow;
    } else if (done) {
      mark = '[✓]';
      color = AppTheme.amberBright;
    } else if (partial) {
      mark = '[~]';
      color = AppTheme.amber;
    } else {
      mark = '[ ]';
      color = AppTheme.textMid;
    }
    return Text(
      mark,
      style: TextStyle(
        fontFamilyFallback: AppTheme.mono,
        fontWeight: FontWeight.w700,
        color: color,
      ),
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
      icon: const Icon(Icons.more_horiz, size: 17, color: AppTheme.textLow),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            showTaskEditorSheet(context, controller, existing: occurrence);
          case 'log':
            showCompleteQuestSheet(context, controller, occurrence);
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
        if (!isPast && controller.canCompleteOn(occurrence.date))
          const PopupMenuItem(value: 'log', child: Text('Log with note…')),
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
    );
  }
}
