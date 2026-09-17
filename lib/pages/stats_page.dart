import 'package:flutter/material.dart';

import '../domain/overview_stats.dart';
import '../domain/statistics.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/terminal_widgets.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  MotivationController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final window = controller.statsWindow;
        final overview = controller.overviewStats(window: window);
        final snapshot = controller.statsSnapshot;
        final wide = MediaQuery.sizeOf(context).width >= 900;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TerminalPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TerminalHeader(
                        'stats --overview',
                        comment: 'progress is the sum of small efforts.',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final w in [
                            DataWindow.d7,
                            DataWindow.d30,
                            DataWindow.d90,
                            DataWindow.all,
                          ])
                            _Chip(
                              label: w.label,
                              selected: window == w,
                              onTap: () => controller.setStatsWindow(w),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _KpiRow(overview: overview, snapshot: snapshot),
                const SizedBox(height: 14),
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _CategoryPanel(controller: controller)),
                          const SizedBox(width: 14),
                          Expanded(child: _DayOfWeekPanel(overview: overview)),
                        ],
                      )
                    : Column(
                        children: [
                          _CategoryPanel(controller: controller),
                          const SizedBox(height: 14),
                          _DayOfWeekPanel(overview: overview),
                        ],
                      ),
                const SizedBox(height: 14),
                TerminalPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TerminalHeader('contributions',
                          comment: 'every completion, one square at a time'),
                      const SizedBox(height: 12),
                      ContributionHeatmap(
                          columns: controller.contributionHeatmap(weeks: 26)),
                      const SizedBox(height: 8),
                      const HeatmapLegend(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.amber.withValues(alpha: 0.18) : AppTheme.cardInset,
          border: Border.all(color: selected ? AppTheme.amber : AppTheme.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text('[$label]',
            style: TextStyle(
                fontFamilyFallback: AppTheme.mono,
                fontSize: 12,
                color: selected ? AppTheme.amberBright : AppTheme.textMid)),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.overview, required this.snapshot});
  final OverviewStats overview;
  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('total xp', '${snapshot.totalXp}'),
      ('level', '${snapshot.level}'),
      ('completions', '${overview.totalCompletions}'),
      ('best streak', '${overview.goalStreak.best}d'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 560 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: [
          for (final (label, value) in tiles)
            TerminalPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontFamilyFallback: AppTheme.mono,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.amberBright)),
                  Text(label,
                      style: const TextStyle(color: AppTheme.textMid, fontSize: 11.5)),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.statsSnapshot;
    final entries = snapshot.xpByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.isEmpty ? 1 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return TerminalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalHeader('xp --by-category'),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text('no data yet.', style: TextStyle(color: AppTheme.textMid))
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(controller.categoryById(entry.key).name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamilyFallback: AppTheme.mono,
                              color: AppTheme.textMid,
                              fontSize: 11.5)),
                    ),
                    Expanded(
                      child: BarProgress(
                        fraction: entry.value / maxV,
                        color: controller.categoryById(entry.key).color,
                        label: '${entry.value}',
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _DayOfWeekPanel extends StatelessWidget {
  const _DayOfWeekPanel({required this.overview});
  final OverviewStats overview;

  @override
  Widget build(BuildContext context) {
    return TerminalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TerminalHeader('day-of-week',
              comment: 'completion rate broken down by day'),
          const SizedBox(height: 12),
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(AppText.weekdayShort[i].toLowerCase(),
                        style: const TextStyle(
                            fontFamilyFallback: AppTheme.mono,
                            color: AppTheme.textMid,
                            fontSize: 11.5)),
                  ),
                  Expanded(
                    child: BarProgress(
                      fraction: overview.dayOfWeekRates[i],
                      color: i == overview.bestWeekday
                          ? AppTheme.successAccent
                          : AppTheme.amber,
                      label: '${(overview.dayOfWeekRates[i] * 100).round()}%',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
