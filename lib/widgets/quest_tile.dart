import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import 'complete_quest_sheet.dart';
import 'task_editor_sheet.dart';

/// One quest row. Tapping an open quest on the current day opens the complete
/// sheet; the trailing menu handles edit / skip / move / copy / remove.
class QuestTile extends StatelessWidget {
  const QuestTile({
    super.key,
    required this.controller,
    required this.occurrence,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final category = controller.categoryById(occurrence.categoryId);
    final canComplete = controller.canCompleteOn(occurrence.date);
    final done = occurrence.isFullyCompleted;
    final partial = occurrence.isCompleted && !done;
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (occurrence.isSkipped) {
            controller.unskipOccurrence(occurrence.id);
          } else if (occurrence.isCompleted) {
            if (canComplete) controller.undoComplete(occurrence.id);
          } else if (canComplete) {
            showCompleteQuestSheet(context, controller, occurrence);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              _StateIcon(done: done, partial: partial, skipped: occurrence.isSkipped),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: occurrence.isSkipped
                            ? TextDecoration.lineThrough
                            : null,
                        color: occurrence.isSkipped
                            ? theme.disabledColor
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(category.icon, size: 13, color: category.color),
                        const SizedBox(width: 4),
                        Text(category.name, style: theme.textTheme.bodySmall),
                        if (occurrence.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.autorenew,
                              size: 12, color: theme.hintColor),
                        ],
                        if (occurrence.isSkipped) ...[
                          const SizedBox(width: 6),
                          Text(AppText.plannedSkip,
                              style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _XpChip(
                xp: occurrence.isCompleted
                    ? occurrence.completion!.awardedXp
                    : occurrence.xp,
                muted: occurrence.isSkipped,
              ),
              _QuestMenu(controller: controller, occurrence: occurrence),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({
    required this.done,
    required this.partial,
    required this.skipped,
  });

  final bool done;
  final bool partial;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    if (skipped) {
      return Icon(Icons.remove_circle_outline, color: Theme.of(context).disabledColor);
    }
    if (done) {
      return const Icon(Icons.check_circle, color: AppTheme.successAccent);
    }
    if (partial) {
      return const Icon(Icons.timelapse, color: AppTheme.xpAccent);
    }
    return Icon(Icons.circle_outlined, color: Theme.of(context).hintColor);
  }
}

class _XpChip extends StatelessWidget {
  const _XpChip({required this.xp, this.muted = false});

  final int xp;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (muted ? Theme.of(context).disabledColor : AppTheme.xpAccent)
            .withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '+$xp',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: muted
              ? Theme.of(context).disabledColor
              : AppTheme.xpAccent.withValues(alpha: 1),
        ),
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
      icon: const Icon(Icons.more_vert, size: 20),
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
