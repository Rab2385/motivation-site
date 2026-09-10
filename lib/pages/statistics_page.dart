import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/statistics.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/donut_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StatsPeriod _period = StatsPeriod.woche;

  MotivationController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final stats = controller.statsSnapshot;
          final period = controller.periodStats(_period);
          final deltaSuffix =
              _period == StatsPeriod.woche ? AppText.vsPrevious : ' vs. Vorperiode';

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppText.statistics,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 26)),
                            const SizedBox(height: 2),
                            const Text(AppText.statisticsSubline,
                                style: TextStyle(color: AppTheme.textMid)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final p in StatsPeriod.values)
                        ChoiceChip(
                          label: Text(p.label),
                          selected: _period == p,
                          onSelected: (_) => setState(() => _period = p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _KpiRow(
                    period: period,
                    stats: stats,
                    deltaSuffix: deltaSuffix,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final chart = Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppText.xpHistory,
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 14),
                            _XpBarChart(period: period),
                          ],
                        ),
                      ),
                    );
                    final donut = Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppText.tasksCompleted,
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Center(
                              child: DonutChart(
                                fraction: period.completedRate,
                                caption:
                                    '${(period.completedRate * period.dueCount).round()} von ${period.dueCount}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (constraints.maxWidth > 640) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: chart),
                          const SizedBox(width: 14),
                          Expanded(flex: 2, child: donut),
                        ],
                      );
                    }
                    return Column(
                        children: [chart, const SizedBox(height: 14), donut]);
                  }),
                  const SizedBox(height: 16),
                  _WeeklyOverview(controller: controller),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('„${AppText.betterNightByNight}"',
                        style: AppTheme.quote, textAlign: TextAlign.center),
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

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.period,
    required this.stats,
    required this.deltaSuffix,
  });

  final PeriodStats period;
  final StatsSnapshot stats;
  final String deltaSuffix;

  @override
  Widget build(BuildContext context) {
    String? d(int? delta) =>
        delta == null ? null : '${delta >= 0 ? '+' : ''}$delta%$deltaSuffix';

    final tiles = [
      _KpiTile(
          value: '${period.tasksDone}',
          label: AppText.doneTasks,
          delta: d(period.tasksDelta)),
      _KpiTile(
          value: '${period.xpEarned}',
          label: AppText.collectedXp,
          delta: d(period.xpDelta)),
      _KpiTile(
          value: '${stats.longestStreakEver}',
          label: AppText.longestStreakLabel),
      _KpiTile(
          value: '${stats.bestCurrentStreak}',
          label: AppText.currentStreakLabel),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 560 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: tiles,
      );
    });
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.value, required this.label, this.delta});
  final String value;
  final String label;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontFamilyFallback: AppTheme.serif,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textHigh)),
            Text(label,
                style: const TextStyle(color: AppTheme.textMid, fontSize: 12)),
            if (delta != null) ...[
              const SizedBox(height: 3),
              Text(delta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.successAccent, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class _XpBarChart extends StatelessWidget {
  const _XpBarChart({required this.period});
  final PeriodStats period;

  @override
  Widget build(BuildContext context) {
    var maxV = 1;
    for (final v in period.bars) {
      if (v > maxV) maxV = v;
    }
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < period.bars.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${period.bars[i]}',
                        style: const TextStyle(
                            color: AppTheme.textLow, fontSize: 10)),
                    const SizedBox(height: 2),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: math.max(period.bars[i] / maxV, 0.02),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFF3C5C8A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      period.barLabels.length > i ? period.barLabels[i] : '',
                      style: const TextStyle(
                          color: AppTheme.textLow, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklyOverview extends StatelessWidget {
  const _WeeklyOverview({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final days = controller.weekDays(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppText.weeklyOverview,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: _DayDot(
                      weekday: AppText.weekdayShort[day.weekday - 1],
                      date: '${day.day}. ${_month(day.month)}',
                      done: isPerfectDay(controller.occurrencesForDay(day)),
                      hasAny:
                          controller.occurrencesForDay(day).isNotEmpty,
                      isFuture: day.isAfter(controller.today),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) => const [
        'Jan', 'Feb', 'März', 'Apr', 'Mai', 'Juni',
        'Juli', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
      ][m - 1];
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.weekday,
    required this.date,
    required this.done,
    required this.hasAny,
    required this.isFuture,
  });

  final String weekday;
  final String date;
  final bool done;
  final bool hasAny;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppTheme.successAccent
        : (isFuture || !hasAny ? AppTheme.textLow : AppTheme.streakAccent);
    return Column(
      children: [
        Text(weekday,
            style: const TextStyle(color: AppTheme.textMid, fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(
            done
                ? Icons.check
                : (isFuture || !hasAny ? Icons.remove : Icons.close),
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(date,
            style: const TextStyle(color: AppTheme.textLow, fontSize: 10)),
      ],
    );
  }
}
