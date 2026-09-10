import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/progression.dart';
import '../domain/workload.dart';
import '../l10n/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/atmosphere.dart';

/// Gold level ring with the level number in the centre.
class LevelRing extends StatelessWidget {
  const LevelRing({super.key, required this.progress, this.size = 116});

  final LevelProgress progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GoldRing(
      fraction: progress.fraction,
      size: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppText.level,
            style: const TextStyle(
              color: AppTheme.textMid,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${progress.level}',
            style: TextStyle(
              fontFamilyFallback: AppTheme.serif,
              color: AppTheme.textHigh,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.3,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal XP bar with a gold gradient fill.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.progress, this.height = 12});

  final LevelProgress progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fill = progress.fraction.clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Container(
            height: height,
            color: const Color(0xFF1B2740),
            alignment: Alignment.centerLeft,
            child: Container(
              height: height,
              width: math.max(constraints.maxWidth * fill, fill > 0 ? 8 : 0),
              decoration: const BoxDecoration(gradient: AppTheme.goldGradient),
            ),
          ),
        );
      },
    );
  }
}

/// Pill used in the hero header ("Streak: 12 Tage" etc.).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = AppTheme.gold,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textHigh, fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Small icon + big number + label, with an optional green delta.
class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.delta,
    this.iconColor = AppTheme.gold,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? delta;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textHigh,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppTheme.textMid, fontSize: 12)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 13, color: AppTheme.successAccent),
                const SizedBox(width: 3),
                Text(delta!,
                    style: const TextStyle(
                        color: AppTheme.successAccent, fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Vertical bar chart for the weekly overview. [values] length 7 (Mon..Sun),
/// [highlightIndex] paints one bar gold.
class WeekBars extends StatelessWidget {
  const WeekBars({
    super.key,
    required this.values,
    this.highlightIndex,
    this.height = 130,
  });

  final List<num> values;
  final int? highlightIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    var maxValue = 1.0;
    for (final value in values) {
      if (value.toDouble() > maxValue) maxValue = value.toDouble();
    }
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor:
                            (values.length > i ? values[i] : 0) / maxValue,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: i == highlightIndex
                                ? AppTheme.gold
                                : const Color(0xFF2E4266),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(AppText.weekdayShort[i],
                        style: const TextStyle(
                            color: AppTheme.textLow, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color colorForBand(WorkloadBand band, BuildContext context) {
  switch (band) {
    case WorkloadBand.leer:
      return const Color(0xFF223052);
    case WorkloadBand.ok:
      return AppTheme.successAccent;
    case WorkloadBand.voll:
      return AppTheme.gold;
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
              Container(height: 8, color: const Color(0xFF1B2740)),
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
