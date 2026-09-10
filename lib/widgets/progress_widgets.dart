import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/progression.dart';
import '../domain/workload.dart';
import '../l10n/app_text.dart';
import '../theme/app_theme.dart';

/// Circular level indicator with the level number in the centre.
class LevelRing extends StatelessWidget {
  const LevelRing({super.key, required this.progress, this.size = 96});

  final LevelProgress progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.fraction.clamp(0.0, 1.0),
              strokeWidth: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.xpAccent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppText.level, style: theme.textTheme.labelSmall),
              Text('${progress.level}',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal XP bar for "XP into this level".
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.fraction.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation(AppTheme.xpAccent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${progress.xpIntoLevel} / ${progress.xpForThisLevel} XP  ·  '
          'noch ${progress.xpToNextLevel} bis Level ${progress.level + 1}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

Color colorForBand(WorkloadBand band, BuildContext context) {
  switch (band) {
    case WorkloadBand.leer:
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    case WorkloadBand.ok:
      return AppTheme.successAccent;
    case WorkloadBand.voll:
      return AppTheme.xpAccent;
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
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              FractionallySizedBox(
                widthFactor: math.max(fill, workload.plannedXp > 0 ? 0.04 : 0.0),
                child: Container(
                  height: 8,
                  color: colorForBand(workload.band, context),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            '${workload.plannedXp} / ${workload.targetXp} XP',
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
