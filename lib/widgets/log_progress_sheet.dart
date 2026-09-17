import 'package:flutter/material.dart';

import '../domain/habit_target.dart';
import '../l10n/app_text.dart';
import '../models/task_occurrence.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';

/// Quick quantity entry for a target-based habit ("6h59min of 7h sleep").
/// Reaching the target auto-completes the habit for full XP.
Future<void> showLogProgressSheet(
  BuildContext context,
  MotivationController controller,
  TaskOccurrence occurrence,
) {
  final target = occurrence.target;
  if (target == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _LogProgressSheet(
      controller: controller,
      occurrence: occurrence,
      target: target,
    ),
  );
}

class _LogProgressSheet extends StatefulWidget {
  const _LogProgressSheet({
    required this.controller,
    required this.occurrence,
    required this.target,
  });

  final MotivationController controller;
  final TaskOccurrence occurrence;
  final HabitTarget target;

  @override
  State<_LogProgressSheet> createState() => _LogProgressSheetState();
}

class _LogProgressSheetState extends State<_LogProgressSheet> {
  late double _amount = widget.occurrence.loggedAmount;

  double get _step {
    switch (widget.target.unit) {
      case TargetUnit.hours:
        return 0.25;
      case TargetUnit.minutes:
        return 5;
      case TargetUnit.steps:
        return 500;
      case TargetUnit.count:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final maxAmount = target.amount * 1.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.logProgress, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(widget.occurrence.title,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => _amount = (_amount - _step).clamp(0, maxAmount)),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    formatTargetProgress(_amount, target),
                    style: const TextStyle(
                      fontFamilyFallback: AppTheme.mono,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.amberBright,
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => _amount = (_amount + _step).clamp(0, maxAmount)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _amount.clamp(0, maxAmount),
            min: 0,
            max: maxAmount,
            onChanged: (value) => setState(() => _amount = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              widget.controller.logProgress(widget.occurrence.id, _amount);
              Navigator.of(context).pop();
            },
            child: Text(
              _amount >= target.amount
                  ? '${AppText.completed} · +${widget.occurrence.xp} XP'
                  : AppText.save,
            ),
          ),
        ],
      ),
    );
  }
}
