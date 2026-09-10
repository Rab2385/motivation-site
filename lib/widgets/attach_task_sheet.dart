import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../services/plan_service.dart';
import '../state/motivation_controller.dart';

/// Pick an existing recurring task to add to [date]. This is the structural
/// no-duplicates path: you never re-type a recurring task, you attach it.
Future<void> showAttachTaskSheet(
  BuildContext context,
  MotivationController controller,
  DateTime date,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final alreadyThere = controller
          .occurrencesForDay(date)
          .map((o) => o.sourceDefinitionId)
          .whereType<String>()
          .toSet();
      final candidates = controller.attachableDefinitions
          .where((d) => !alreadyThere.contains(d.id))
          .toList();

      return SafeArea(
        child: candidates.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Keine weiteren Gewohnheiten zum Hinzufügen.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      AppText.attachExisting,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final definition in candidates)
                    ListTile(
                      leading: Icon(
                        controller.categoryById(definition.categoryId).icon,
                        color: controller.categoryById(definition.categoryId).color,
                      ),
                      title: Text(definition.title),
                      subtitle: Text('+${definition.xp} XP'),
                      onTap: () async {
                        final scope = await _askScope(context, date);
                        if (scope == null) return;
                        await controller.attachDefinitionToDate(
                          definitionId: definition.id,
                          date: date,
                          scope: scope,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
      );
    },
  );
}

Future<AttachScope?> _askScope(BuildContext context, DateTime date) {
  final weekday = AppText.weekdayLong[date.weekday - 1];
  return showDialog<AttachScope>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppText.attachScopeQuestion),
      content: Text(
        'Diese Gewohnheit fällt sonst nicht auf $weekday.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(AttachScope.thisDateOnly),
          child: const Text(AppText.attachOnce),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(AttachScope.everyWeekdayFromNow),
          child: Text('${AppText.attachEvery}$weekday'),
        ),
      ],
    ),
  );
}
