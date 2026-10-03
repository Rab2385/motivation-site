import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../services/plan_service.dart';
import '../state/motivation_controller.dart';

/// Pick an existing recurring task to add to [date].
Future<void> showAttachTaskSheet(
  BuildContext context,
  MotivationController controller,
  DateTime date,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AttachTaskSheet(controller: controller, date: date),
  );
}

class _AttachTaskSheet extends StatefulWidget {
  const _AttachTaskSheet({required this.controller, required this.date});

  final MotivationController controller;
  final DateTime date;

  @override
  State<_AttachTaskSheet> createState() => _AttachTaskSheetState();
}

class _AttachTaskSheetState extends State<_AttachTaskSheet> {
  String _query = '';
  String _filter = 'all';

  static const List<String> _filters = [
    'all',
    'morning',
    'afternoon',
    'night',
    'general',
  ];

  @override
  Widget build(BuildContext context) {
    final alreadyThere = widget.controller
        .occurrencesForDay(widget.date)
        .map((o) => o.sourceDefinitionId)
        .whereType<String>()
        .toSet();

    final candidates = widget.controller.attachableDefinitions
        .where((d) => !alreadyThere.contains(d.id))
        .toList();

    final filtered = candidates.where((definition) {
      final category = widget.controller.categoryById(definition.categoryId);
      final section = definition.section.trim();
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          definition.title.toLowerCase().contains(normalizedQuery) ||
          category.name.toLowerCase().contains(normalizedQuery) ||
          section.toLowerCase().contains(normalizedQuery);

      final matchesFilter = switch (_filter) {
        'morning' => section.toLowerCase() == 'morning',
        'afternoon' => section.toLowerCase() == 'afternoon',
        'night' => section.toLowerCase() == 'night',
        'general' => section.isEmpty,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();

    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppText.attachExisting, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: AppText.searchHabits,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final value = _filters[index];
                    final label = switch (value) {
                      'all' => AppText.all,
                      'morning' => AppText.morning,
                      'afternoon' => AppText.afternoon,
                      'night' => AppText.night,
                      _ => AppText.general,
                    };
                    final selected = _filter == value;

                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No habits match this filter.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final definition = filtered[index];
                          final category = widget.controller.categoryById(
                            definition.categoryId,
                          );
                          final section = definition.section.trim();
                          final label = section.isEmpty
                              ? AppText.general
                              : section;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(category.icon, color: category.color),
                            ),
                            title: Text(definition.title),
                            subtitle: Text('$label • +${definition.xp} XP'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: category.color.withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: category.color,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            onTap: () async {
                              final scope = await _askScope(
                                context,
                                widget.date,
                                definition.title,
                              );
                              if (scope == null) return;
                              await widget.controller.attachDefinitionToDate(
                                definitionId: definition.id,
                                date: widget.date,
                                scope: scope,
                              );
                              if (context.mounted) Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<AttachScope?> _askScope(
  BuildContext context,
  DateTime date,
  String habitTitle,
) {
  final weekday = AppText.weekdayLong[date.weekday - 1];
  return showDialog<AttachScope>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add $habitTitle to $weekday?'),
      content: Text('This habit does not normally fall on $weekday.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(AttachScope.thisDateOnly),
          child: const Text(AppText.attachOnce),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(AttachScope.everyWeekdayFromNow),
          child: const Text(AppText.attachEvery),
        ),
      ],
    ),
  );
}
