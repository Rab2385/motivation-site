import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/difficulty.dart';
import '../l10n/app_text.dart';
import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';

/// One sheet for: new one-off, new recurring, edit occurrence, edit definition.
Future<void> showTaskEditorSheet(
  BuildContext context,
  MotivationController controller, {
  DateTime? date,
  TaskOccurrence? existing,
  TaskDefinition? definition,
  bool startAsRecurring = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TaskEditorSheet(
      controller: controller,
      date: date,
      existing: existing,
      definition: definition,
      startAsRecurring: startAsRecurring,
    ),
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.controller,
    this.date,
    this.existing,
    this.definition,
    this.startAsRecurring = false,
  });

  final MotivationController controller;
  final DateTime? date;
  final TaskOccurrence? existing;
  final TaskDefinition? definition;
  final bool startAsRecurring;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _xp;

  late String _categoryId;
  Difficulty? _difficulty;
  bool _recurring = false;
  RecurrenceKind _recurrenceKind = RecurrenceKind.fixedWeekdays;
  final Set<int> _weekdays = {};
  int _timesPerWeek = 3;
  bool _xpTouched = false;

  bool get _isEditOccurrence => widget.existing != null;
  bool get _isEditDefinition => widget.definition != null;

  @override
  void initState() {
    super.initState();
    final source = widget.existing;
    final def = widget.definition;

    _title = TextEditingController(text: source?.title ?? def?.title ?? '');
    _note = TextEditingController(text: source?.note ?? def?.note ?? '');
    _categoryId = source?.categoryId ??
        def?.categoryId ??
        widget.controller.activeCategories.firstOrNull?.id ??
        'fitness';
    _difficulty = source?.difficulty ?? def?.difficulty;
    final initialXp = source?.xp ?? def?.xp ?? suggestedFor(_difficulty);
    _xp = TextEditingController(text: '$initialXp');
    _xpTouched = source != null || def != null;

    if (def != null) {
      _recurring = true;
      _recurrenceKind = def.recurrence.kind;
      _weekdays.addAll(def.recurrence.weekdays);
      _timesPerWeek =
          def.recurrence.timesPerWeek == 0 ? 3 : def.recurrence.timesPerWeek;
    } else if (widget.startAsRecurring) {
      _recurring = true;
    }
    if (_weekdays.isEmpty && widget.date != null) {
      _weekdays.add(widget.date!.weekday);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _xp.dispose();
    super.dispose();
  }

  static int suggestedFor(Difficulty? difficulty) =>
      difficulty?.defaultXp ?? Difficulty.mittel.defaultXp;

  void _pickDifficulty(Difficulty? value) {
    setState(() {
      _difficulty = value;
      if (!_xpTouched && value != null) {
        _xp.text = '${value.defaultXp}';
      }
    });
  }

  bool get _canSave {
    if (_title.text.trim().isEmpty) return false;
    if (_recurring && _recurrenceKind == RecurrenceKind.fixedWeekdays) {
      return _weekdays.isNotEmpty;
    }
    return true;
  }

  Future<void> _save() async {
    final controller = widget.controller;
    final title = _title.text.trim();
    final note = _note.text.trim();
    final xp = int.tryParse(_xp.text.trim()) ?? suggestedFor(_difficulty);

    if (_isEditOccurrence) {
      await controller.editOccurrence(
        widget.existing!.id,
        title: title,
        note: note,
        categoryId: _categoryId,
        difficulty: _difficulty,
        clearDifficulty: _difficulty == null,
        xp: xp,
      );
    } else if (_isEditDefinition) {
      await controller.editDefinition(
        widget.definition!.id,
        title: title,
        note: note,
        categoryId: _categoryId,
        difficulty: _difficulty,
        clearDifficulty: _difficulty == null,
        xp: xp,
        recurrence: _buildRecurrence(),
      );
    } else if (_recurring) {
      await controller.createRecurring(
        title: title,
        note: note,
        categoryId: _categoryId,
        xp: xp,
        difficulty: _difficulty,
        recurrence: _buildRecurrence(),
      );
    } else {
      await controller.addOneOff(
        date: widget.date ?? controller.today,
        title: title,
        note: note,
        categoryId: _categoryId,
        xp: xp,
        difficulty: _difficulty,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  RecurrenceRule _buildRecurrence() {
    return _recurrenceKind == RecurrenceKind.fixedWeekdays
        ? RecurrenceRule.fixedWeekdays(Set.of(_weekdays))
        : RecurrenceRule.timesPerWeek(_timesPerWeek);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categories = widget.controller.activeCategories;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditOccurrence || _isEditDefinition
                  ? AppText.edit
                  : (_recurring ? AppText.newRecurring : AppText.newOneOff),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: !_isEditOccurrence && !_isEditDefinition,
              decoration: const InputDecoration(labelText: AppText.title),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: AppText.category),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 16, color: category.color),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _categoryId = value ?? _categoryId),
            ),
            const SizedBox(height: 12),
            Text(AppText.difficultyOptional, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final difficulty in Difficulty.values)
                  ChoiceChip(
                    label: Text(difficulty.label),
                    selected: _difficulty == difficulty,
                    onSelected: (selected) =>
                        _pickDifficulty(selected ? difficulty : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _xp,
              decoration: const InputDecoration(labelText: AppText.xp),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _xpTouched = true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: AppText.note),
              minLines: 1,
              maxLines: 3,
            ),
            if (!_isEditOccurrence) ...[
              const SizedBox(height: 8),
              if (!_isEditDefinition)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppText.repeat),
                  value: _recurring,
                  onChanged: (value) => setState(() => _recurring = value),
                ),
              if (_recurring) _recurrenceEditor(theme),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: const Text(AppText.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recurrenceEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<RecurrenceKind>(
          segments: const [
            ButtonSegment(
              value: RecurrenceKind.fixedWeekdays,
              label: Text(AppText.fixedWeekdays),
            ),
            ButtonSegment(
              value: RecurrenceKind.timesPerWeek,
              label: Text(AppText.timesPerWeek),
            ),
          ],
          selected: {_recurrenceKind},
          onSelectionChanged: (value) =>
              setState(() => _recurrenceKind = value.first),
        ),
        const SizedBox(height: 12),
        if (_recurrenceKind == RecurrenceKind.fixedWeekdays)
          Wrap(
            spacing: 6,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  label: Text(AppText.weekdayShort[weekday - 1]),
                  selected: _weekdays.contains(weekday),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _weekdays.add(weekday);
                    } else {
                      _weekdays.remove(weekday);
                    }
                  }),
                ),
            ],
          )
        else
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _timesPerWeek > 1
                    ? () => setState(() => _timesPerWeek--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_timesPerWeek × / Woche',
                    style: theme.textTheme.titleMedium),
              ),
              IconButton.filledTonal(
                onPressed: _timesPerWeek < 7
                    ? () => setState(() => _timesPerWeek++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
      ],
    );
  }
}
