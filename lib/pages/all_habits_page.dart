import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../state/motivation_controller.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/task_editor_sheet.dart';

class AllHabitsPage extends StatefulWidget {
  const AllHabitsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<AllHabitsPage> createState() => _AllHabitsPageState();
}

class _AllHabitsPageState extends State<AllHabitsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  List<TaskDefinition> get _filteredHabits {
    final query = _query;
    final habits = widget.controller.activeDefinitions;
    if (query.isEmpty) return habits;

    return habits.where((habit) {
      final category = widget.controller.categoryById(habit.categoryId).name;
      final haystack = [
        habit.title,
        habit.section,
        category,
        habit.note,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  String _recurrenceSummary(TaskDefinition definition) {
    switch (definition.recurrence.kind) {
      case RecurrenceKind.fixedWeekdays:
        final days = definition.recurrence.weekdays.toList()..sort();
        final labels = days
            .map((day) => AppText.weekdayShort[day - 1])
            .join(', ');
        return labels.isEmpty ? 'Fixed weekdays' : labels;
      case RecurrenceKind.timesPerWeek:
        return '${definition.recurrence.timesPerWeek} / week';
      case RecurrenceKind.monthly:
        return 'Monthly · ${definition.recurrence.dayOfMonth}';
    }
  }

  Future<void> _deleteHabit(TaskDefinition habit) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isConfirmed = controller.text.trim() == habit.title.trim();
          return AlertDialog(
            title: const Text('Delete habit'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This removes the habit and its future scheduled occurrences. \n\nType “${habit.title}” to confirm.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Enter habit name',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppText.cancel),
              ),
              FilledButton(
                onPressed: isConfirmed
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text(AppText.delete),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;
    await widget.controller.deleteDefinition(habit.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Habit deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final habits = _filteredHabits;

    return PageScaffold(
      title: 'all habits',
      subtitle: '// searchable recurring habits',
      listenable: widget.controller,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditorSheet(
          context,
          widget.controller,
          startAsRecurring: true,
        ),
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppText.searchHabits,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Text(
                        'No habits match your search.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: habits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final category = widget.controller.categoryById(
                          habit.categoryId,
                        );
                        final summary = [
                          if (habit.section.isNotEmpty) habit.section,
                          _recurrenceSummary(habit),
                        ].join(' • ');

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: category.color.withValues(
                                alpha: 0.15,
                              ),
                              child: Icon(category.icon, color: category.color),
                            ),
                            title: Text(habit.title),
                            subtitle: Text(summary),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: AppText.edit,
                                  onPressed: () => showTaskEditorSheet(
                                    context,
                                    widget.controller,
                                    definition: habit,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: AppText.delete,
                                  onPressed: () => _deleteHabit(habit),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
