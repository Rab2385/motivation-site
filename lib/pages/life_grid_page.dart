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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 20),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text('life grid',
                            style: TextStyle(
                                fontFamilyFallback: AppTheme.mono,
                                color: AppTheme.textHigh,
                                fontWeight: FontWeight.w700,
                                fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TerminalPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TerminalHeader('central goal'),
                        const SizedBox(height: 10),
                        Text('"$lifeGridCentralGoal"',
                            style: const TextStyle(
                                color: AppTheme.textHigh,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.4)),
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
                        const TerminalHeader('eight life areas',
                            comment: 'focus areas are your current 90-day priorities; '
                                'the rest stay in maintenance mode.'),
                        const SizedBox(height: 14),
                        LayoutBuilder(builder: (context, constraints) {
                          final cols = constraints.maxWidth > 760
                              ? 2
                              : 1;
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: cols == 2 ? 1.9 : 2.6,
                            children: [
                              for (final category in controller.lifeAreaCategories)
                                _LifeAreaCard(controller: controller, category: category),
                            ],
                          );
                        }),
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
        Icon(done ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label  ',
            style: const TextStyle(
                fontFamilyFallback: AppTheme.mono, color: AppTheme.textMid, fontSize: 12)),
        Text(text,
            style: TextStyle(
                fontFamilyFallback: AppTheme.mono,
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
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
                child: Text(category.name,
                    style: const TextStyle(
                        fontFamilyFallback: AppTheme.mono,
                        color: AppTheme.textHigh,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
              _FocusBadge(isFocus: category.isFocusArea),
            ],
          ),
          const SizedBox(height: 6),
          Text('+$xpThisMonth xp this month',
              style: const TextStyle(
                  fontFamilyFallback: AppTheme.mono, color: AppTheme.textLow, fontSize: 11)),
          const SizedBox(height: 8),
          if (milestones.isEmpty)
            const Text('no milestones yet',
                style: TextStyle(color: AppTheme.textLow, fontSize: 11.5))
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
}

class _FocusBadge extends StatelessWidget {
  const _FocusBadge({required this.isFocus});
  final bool isFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFocus ? AppTheme.amber.withValues(alpha: 0.16) : Colors.transparent,
        border: Border.all(color: isFocus ? AppTheme.amber : AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isFocus ? 'focus' : 'maintenance',
        style: TextStyle(
            fontFamilyFallback: AppTheme.mono,
            fontSize: 9.5,
            color: isFocus ? AppTheme.amberBright : AppTheme.textLow),
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
            Text(milestone.status.symbol,
                style: const TextStyle(fontSize: 13, color: AppTheme.amberBright)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(milestone.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textHigh, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleStatus(BuildContext context) {
    const order = [GoalStatus.notStarted, GoalStatus.inProgress, GoalStatus.achieved];
    final next = order[(order.indexOf(milestone.status) + 1) % order.length];
    controller.setMilestoneStatus(milestone.id, next);
  }
}
