import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';

Future<void> showCompleteQuestSheet(
  BuildContext context,
  MotivationController controller,
  TaskOccurrence occurrence,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CompleteQuestSheet(
      controller: controller,
      occurrence: occurrence,
    ),
  );
}

class _CompleteQuestSheet extends StatefulWidget {
  const _CompleteQuestSheet({
    required this.controller,
    required this.occurrence,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;

  @override
  State<_CompleteQuestSheet> createState() => _CompleteQuestSheetState();
}

class _CompleteQuestSheetState extends State<_CompleteQuestSheet> {
  final _noteController = TextEditingController();
  bool _partial = false;
  double _fraction = 0.5;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _xp {
    final base = widget.occurrence.xp;
    return _partial ? (base * _fraction).round() : base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.completeQuest, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(widget.occurrence.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text(AppText.fullyDone)),
              ButtonSegment(value: true, label: Text(AppText.partial)),
            ],
            selected: {_partial},
            onSelectionChanged: (value) =>
                setState(() => _partial = value.first),
          ),
          if (_partial) ...[
            const SizedBox(height: 16),
            Text(AppText.howMuch, style: theme.textTheme.bodyMedium),
            Slider(
              value: _fraction,
              min: 0.1,
              max: 0.95,
              divisions: 17,
              label: '${(_fraction * 100).round()} %',
              onChanged: (value) => setState(() => _fraction = value),
            ),
            Text(AppText.partialHint, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: AppText.optionalNote),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    widget.controller.completeQuest(
                      widget.occurrence.id,
                      fraction: _partial ? _fraction : 1.0,
                      note: _noteController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check),
                  label: Text('${AppText.completed}  ·  +$_xp XP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
