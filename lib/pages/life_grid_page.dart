import 'package:flutter/material.dart';

import '../domain/life_grid.dart';
import '../models/milestone.dart';
import '../models/task_category.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/terminal_widgets.dart';

/// The deeper Life Grid overview: the central goal, the 90-day focus, the
/// Minimum Viable Week, and all eight life areas with their milestones.
/// Reached from the dashboard's top bar — kept off the main day-to-day nav
/// on purpose (progressive disclosure: today/this week stay primary).
class LifeGridPage extends StatelessWidget {
  const LifeGridPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'life grid',
                      style: TextStyle(
                        fontFamilyFallback: AppTheme.mono,
                        color: AppTheme.textHigh,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TerminalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TerminalHeader('central goal'),
                        const SizedBox(height: 10),
                        Text(
                          '"$lifeGridCentralGoal"',
                          style: const TextStyle(
                            color: AppTheme.textHigh,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MinimumViableWeekCard(controller: controller),
                  const SizedBox(height: 14),
                  TerminalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TerminalHeader(
                          'eight life areas',
                          comment:
                              'focus areas are your current 90-day priorities; '
                              'the rest stay in maintenance mode.',
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth > 760 ? 2 : 1;
                            return GridView.count(
                              crossAxisCount: cols,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: cols == 2 ? 1.9 : 2.6,
                              children: [
                                for (final category
                                    in controller.lifeAreaCategories)
                                  _LifeAreaCard(
                                    controller: controller,
                                    category: category,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MinimumViableWeekCard extends StatelessWidget {
  const _MinimumViableWeekCard({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.minimumViableWeekStatus;
    return TerminalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalHeader(
            'minimum viable week',
            comment: 'a meaningful week, not a perfect one.',
            trailing: Icon(
              status.isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: status.isMet ? AppTheme.successAccent : AppTheme.textLow,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _MvwItem(
                label: 'workouts',
                done: status.workoutsMet,
                text: '${status.workoutsDone}/${status.workoutsTarget}',
              ),
              _MvwItem(
                label: 'build session',
                done: status.deepBuildDone,
                text: status.deepBuildDone ? 'done' : 'open',
              ),
              _MvwItem(
                label: 'courage challenge',
                done: status.courageDone,
                text: status.courageDone ? 'done' : 'open',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MvwItem extends StatelessWidget {
  const _MvwItem({required this.label, required this.done, required this.text});
  final String label;
  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppTheme.successAccent : AppTheme.textMid;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle_outline : Icons.circle_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: const TextStyle(
            fontFamilyFallback: AppTheme.mono,
            color: AppTheme.textMid,
            fontSize: 12,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamilyFallback: AppTheme.mono,
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LifeAreaCard extends StatelessWidget {
  const _LifeAreaCard({required this.controller, required this.category});

  final MotivationController controller;
  final TaskCategory category;

  @override
  Widget build(BuildContext context) {
    final milestones = controller.milestonesForCategory(category.id);
    final xpThisMonth = controller.xpThisMonthForCategory(category.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        border: Border.all(
          color: category.isFocusArea
              ? category.color.withValues(alpha: 0.55)
              : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 15, color: category.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    color: AppTheme.textHigh,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              _FocusBadge(isFocus: category.isFocusArea),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'add milestone',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showAddMilestoneDialog(context, category),
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.amberBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '+$xpThisMonth xp this month',
            style: const TextStyle(
              fontFamilyFallback: AppTheme.mono,
              color: AppTheme.textLow,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showAddMilestoneDialog(context, category),
            icon: const Icon(Icons.add, size: 14),
            label: const Text(
              'add milestone',
              style: TextStyle(
                fontFamilyFallback: AppTheme.mono,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (milestones.isEmpty)
            const Text(
              'no milestones yet',
              style: TextStyle(color: AppTheme.textLow, fontSize: 11.5),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final milestone in milestones)
                    _MilestoneRow(controller: controller, milestone: milestone),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, TaskCategory category) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _AddMilestoneDialog(controller: controller, category: category),
    );
  }
}

class _AddMilestoneDialog extends StatefulWidget {
  const _AddMilestoneDialog({required this.controller, required this.category});

  final MotivationController controller;
  final TaskCategory category;

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _xpController = TextEditingController(text: '50');
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final xp = int.tryParse(_xpController.text.trim()) ?? 50;

    setState(() => _saving = true);
    try {
      await widget.controller.addMilestone(
        title: title,
        categoryId: widget.category.id,
        xp: xp,
        description: description,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgRaised,
      title: Text(
        'new milestone',
        style: TextStyle(
          fontFamilyFallback: AppTheme.mono,
          color: AppTheme.textHigh,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal',
                  hintText: 'Publish an app',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Add a goal title.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'One concrete action or deadline.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _xpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'XP reward'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Use a positive number.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'saving...' : 'save'),
        ),
      ],
    );
  }
}

class _FocusBadge extends StatelessWidget {
  const _FocusBadge({required this.isFocus});
  final bool isFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFocus
            ? AppTheme.amber.withValues(alpha: 0.16)
            : Colors.transparent,
        border: Border.all(color: isFocus ? AppTheme.amber : AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isFocus ? 'focus' : 'maintenance',
        style: TextStyle(
          fontFamilyFallback: AppTheme.mono,
          fontSize: 9.5,
          color: isFocus ? AppTheme.amberBright : AppTheme.textLow,
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.controller, required this.milestone});

  final MotivationController controller;
  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _cycleStatus(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              milestone.status.symbol,
              style: const TextStyle(fontSize: 13, color: AppTheme.amberBright),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                milestone.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textHigh, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleStatus(BuildContext context) {
    const order = [
      GoalStatus.notStarted,
      GoalStatus.inProgress,
      GoalStatus.achieved,
    ];
    final next = order[(order.indexOf(milestone.status) + 1) % order.length];
    controller.setMilestoneStatus(milestone.id, next);
  }
}
