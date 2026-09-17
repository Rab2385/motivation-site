import 'package:flutter/material.dart';

import '../domain/overview_stats.dart';
import '../theme/app_theme.dart';

/// GitHub-style contribution grid: columns are weeks, rows are Mon..Sun.
class ContributionHeatmap extends StatelessWidget {
  const ContributionHeatmap({
    super.key,
    required this.columns,
    this.cellSize = 10,
    this.gap = 3,
  });

  final List<List<HeatCell>> columns;
  final double cellSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final column in columns)
            Padding(
              padding: EdgeInsets.only(right: gap),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final cell in column)
                    Padding(
                      padding: EdgeInsets.only(bottom: gap),
                      child: Tooltip(
                        message: cell.level < 0
                            ? ''
                            : '${cell.date.month}/${cell.date.day}: '
                                '${cell.level == 0 ? 'nothing' : 'level ${cell.level}'}',
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: cell.level < 0
                                ? Colors.transparent
                                : AppTheme.heatLevels[cell.level],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
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

/// The "less … more" legend under the heatmap.
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('less',
            style: TextStyle(color: AppTheme.textLow, fontSize: 10)),
        const SizedBox(width: 4),
        for (final color in AppTheme.heatLevels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 4),
        const Text('more',
            style: TextStyle(color: AppTheme.textLow, fontSize: 10)),
      ],
    );
  }
}
