import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/workload.dart';
import '../theme/app_theme.dart';

Color colorForBand(WorkloadBand band, BuildContext context) {
  switch (band) {
    case WorkloadBand.leer:
      return const Color(0xFF1B2534);
    case WorkloadBand.ok:
      return AppTheme.successAccent;
    case WorkloadBand.voll:
      return AppTheme.amber;
    case WorkloadBand.ueberladen:
      return AppTheme.streakAccent;
  }
}

/// Thin workload bar: planned XP against the day's target.
class WorkloadBar extends StatelessWidget {
  const WorkloadBar({super.key, required this.workload, this.showLabel = true});

  final DayWorkload workload;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = workload.load.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(height: 6, color: const Color(0xFF1B2534)),
              FractionallySizedBox(
                widthFactor: math.max(fill, workload.plannedXp > 0 ? 0.04 : 0.0),
                child: Container(
                  height: 6,
                  color: colorForBand(workload.band, context),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            '${workload.plannedXp} / ${workload.targetXp} xp',
            style: theme.textTheme.bodySmall?.copyWith(
              color: workload.isOverloaded ? AppTheme.streakAccent : null,
              fontWeight:
                  workload.isOverloaded ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
