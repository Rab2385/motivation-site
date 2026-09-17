import 'package:flutter/material.dart';

import '../domain/overview_stats.dart';
import '../l10n/app_text.dart';
import '../l10n/quotes.dart';
import '../models/task_occurrence.dart';
import '../state/home_nav_state.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../util/dates.dart';
import '../widgets/attach_task_sheet.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/quest_tile.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/terminal_widgets.dart';

/// The "habits" home screen — the terminal-style three-column dashboard:
/// status/calendar/heatmap, the day's habit list grouped by section, and a
/// closeable stats overview panel.
class HabitsHomePage extends StatelessWidget {
  const HabitsHomePage({super.key, required this.controller, required this.nav});

  final MotivationController controller;
  final HomeNavState nav;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, nav]),
      builder: (context, _) {
        final today = controller.today;
        final date = nav.date;
        final width = MediaQuery.sizeOf(context).width;

        final center = _CenterColumn(
          controller: controller,
          date: date,
          today: today,
          onShiftDay: nav.shiftDay,
        );

        if (width >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 270,
                child: _LeftColumn(controller: controller, date: date),
              ),
              const SizedBox(width: 14),
              Expanded(child: center),
              const SizedBox(width: 14),
              if (nav.statsOpen)
                SizedBox(
                  width: 300,
                  child: _RightColumn(
                    controller: controller,
                    onClose: () => nav.setStatsOpen(false),
                  ),
                )
              else
                _ReopenStatsButton(onTap: () => nav.setStatsOpen(true)),
            ],
          );
        }

        if (width >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _CompactStatus(controller: controller),
                    const SizedBox(height: 14),
                    center,
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 280,
                child: _RightColumn(controller: controller, onClose: null),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _CompactStatus(controller: controller),
            const SizedBox(height: 14),
            _WeekStrip(controller: controller, selected: date, onSelect: (d) {
              nav.shiftDay(d.difference(nav.date).inDays);
            }),
            const SizedBox(height: 14),
            center,
          ],
        );
      },
    );
  }
}

class _ReopenStatsButton extends StatelessWidget {
  const _ReopenStatsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: onTap,
        tooltip: 'open stats',
        icon: const Icon(Icons.bar_chart, color: AppTheme.textMid),
      ),
    );
  }
}

// ---- Left column: status + calendar + contributions -----------------------

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.controller, required this.date});

  final MotivationController controller;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalPanel(child: _StatusBlock(controller: controller)),
          const SizedBox(height: 14),
          TerminalPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TerminalHeader('calendar'),
                const SizedBox(height: 10),
                MiniCalendar(controller: controller),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TerminalPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TerminalHeader('contributions'),
                const SizedBox(height: 10),
                ContributionHeatmap(columns: controller.contributionHeatmap()),
                const SizedBox(height: 8),
                const HeatmapLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final today = controller.today;
    final progress = controller.levelProgress;
    final todays = controller.todaysQuests;
    final done = todays.where((o) => o.isCompleted).length;
    final overview = controller.overviewStats(window: DataWindow.d30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TerminalHeader('status'),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMid),
            const SizedBox(width: 6),
            Expanded(
              child: Text(longDate(today),
                  style: const TextStyle(
                      fontFamilyFallback: AppTheme.mono,
                      color: AppTheme.textHigh,
                      fontSize: 11.5)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.local_fire_department, size: 13, color: AppTheme.streakAccent),
            Text(' ${overview.goalStreak.current} days',
                style: const TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    color: AppTheme.textHigh,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Text('*', style: TextStyle(color: AppTheme.textLow)),
            const SizedBox(width: 8),
            const Icon(Icons.shield_outlined, size: 13, color: AppTheme.textMid),
            Text(' ${controller.rewards.where((r) => r.isUnlocked(progress.level)).length}',
                style: const TextStyle(
                    fontFamilyFallback: AppTheme.mono, color: AppTheme.textHigh, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        BarProgress(
          fraction: todays.isEmpty ? 0 : done / todays.length,
          label: '${todays.isEmpty ? 0 : (done / todays.length * 100).round()}% '
              '[$done/${todays.length}]',
        ),
        const SizedBox(height: 4),
        Text('// goal: ${controller.dailyGoalPercent}%',
            style: AppTheme.comment.copyWith(fontSize: 11)),
        const SizedBox(height: 10),
        Text('level: ${progress.level} [${progress.xpToNextLevel}xp to next]',
            style: const TextStyle(
                fontFamilyFallback: AppTheme.mono,
                color: AppTheme.amberBright,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CompactStatus extends StatelessWidget {
  const _CompactStatus({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.levelProgress;
    final todays = controller.todaysQuests;
    final done = todays.where((o) => o.isCompleted).length;
    final overview = controller.overviewStats(window: DataWindow.d30);

    return TerminalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(greetingFor(DateTime.now()),
                  style: const TextStyle(
                      fontFamilyFallback: AppTheme.mono,
                      color: AppTheme.textHigh,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.local_fire_department,
                  size: 14, color: overview.goalStreak.current > 0
                      ? AppTheme.streakAccent
                      : AppTheme.textLow),
              Text(' ${overview.goalStreak.current}d',
                  style: const TextStyle(fontFamilyFallback: AppTheme.mono, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text('// ${quoteOfTheDay(DateTime.now())}',
              style: AppTheme.comment.copyWith(fontSize: 11)),
          const SizedBox(height: 10),
          BarProgress(
            fraction: todays.isEmpty ? 0 : done / todays.length,
            label: 'level ${progress.level} · $done/${todays.length}',
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.controller, required this.selected, required this.onSelect});

  final MotivationController controller;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final monday = weekStart(selected);
    final days = daysInRange(monday, monday.add(const Duration(days: 6)));
    return TerminalPanel(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSameDay(day, selected)
                        ? AppTheme.amber.withValues(alpha: 0.16)
                        : null,
                    border: isSameDay(day, controller.today)
                        ? Border.all(color: AppTheme.amber)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(AppText.weekdayShort[day.weekday - 1],
                          style: const TextStyle(
                              fontFamilyFallback: AppTheme.mono,
                              color: AppTheme.textLow,
                              fontSize: 10)),
                      const SizedBox(height: 2),
                      Text('${day.day}',
                          style: TextStyle(
                              fontFamilyFallback: AppTheme.mono,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isSameDay(day, selected)
                                  ? AppTheme.amberBright
                                  : AppTheme.textHigh)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Center column: the habit list ----------------------------------------

class _CenterColumn extends StatelessWidget {
  const _CenterColumn({
    required this.controller,
    required this.date,
    required this.today,
    required this.onShiftDay,
  });

  final MotivationController controller;
  final DateTime date;
  final DateTime today;
  final void Function(int delta) onShiftDay;

  @override
  Widget build(BuildContext context) {
    final grouped = controller.groupedHabitsForDay(date);
    final isToday = isSameDay(date, today);
    final isPast = date.isBefore(today);

    return TerminalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalHeader(
            AppText.habits,
            comment: "the checkbox doesn't care if you feel like it.",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onShiftDay(-1),
                  icon: const Icon(Icons.chevron_left, size: 18, color: AppTheme.textMid),
                ),
                Text(
                  isToday ? 'today' : '${date.day}/${date.month}',
                  style: const TextStyle(fontFamilyFallback: AppTheme.mono, fontSize: 12),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onShiftDay(1),
                  icon: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMid),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (grouped.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          isPast ? 'nothing was scheduled that day.' : AppText.noQuestsToday,
                          style: const TextStyle(color: AppTheme.textMid),
                        ),
                      ),
                    )
                  else
                    for (final entry in grouped) _SectionBlock(
                      controller: controller,
                      section: entry.key,
                      occurrences: entry.value,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (!isPast)
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => showTaskEditorSheet(context, controller, date: date),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('+ habit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => showTaskEditorSheet(context, controller,
                      date: date, startAsRecurring: true),
                  icon: const Icon(Icons.autorenew, size: 15),
                  label: const Text('+ routine'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => showAttachTaskSheet(context, controller, date),
                  child: const Text('attach existing'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatefulWidget {
  const _SectionBlock({
    required this.controller,
    required this.section,
    required this.occurrences,
  });

  final MotivationController controller;
  final String section;
  final List<TaskOccurrence> occurrences;

  @override
  State<_SectionBlock> createState() => _SectionBlockState();
}

class _SectionBlockState extends State<_SectionBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final done = widget.occurrences.where((o) => o.isCompleted).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(sectionEmojiOrDot(widget.section), style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(widget.section,
                      style: const TextStyle(
                          fontFamilyFallback: AppTheme.mono,
                          color: AppTheme.textHigh,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                  const SizedBox(width: 6),
                  Text('[$done/${widget.occurrences.length}]',
                      style: const TextStyle(
                          fontFamilyFallback: AppTheme.mono,
                          color: AppTheme.textLow,
                          fontSize: 11.5)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16, color: AppTheme.textLow),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (var i = 0; i < widget.occurrences.length; i++)
              QuestTile(
                controller: widget.controller,
                occurrence: widget.occurrences[i],
                flat: true,
                showStreak: true,
                showDivider: i < widget.occurrences.length - 1,
              ),
        ],
      ),
    );
  }
}

String sectionEmojiOrDot(String section) {
  const map = {
    'morning': '\u{1F305}',
    'afternoon': '☀️',
    'deep work': '\u{1F4BB}',
    'evening': '\u{1F306}',
    'wind down': '\u{1F319}',
    'night': '\u{1F319}',
    'general': '\u{1F4CC}',
  };
  return map[section.trim().toLowerCase()] ?? '▸';
}

// ---- Right column: stats overview ------------------------------------------

class _RightColumn extends StatefulWidget {
  const _RightColumn({required this.controller, required this.onClose});

  final MotivationController controller;
  final VoidCallback? onClose;

  @override
  State<_RightColumn> createState() => _RightColumnState();
}

class _RightColumnState extends State<_RightColumn> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final window = controller.statsWindow;
    final overview = controller.overviewStats(window: window);

    return TerminalPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TerminalHeader(
              'stats --overview',
              trailing: widget.onClose == null
                  ? null
                  : IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, size: 16, color: AppTheme.textLow),
                    ),
            ),
            const SizedBox(height: 14),
            _StatSection(
              title: 'lifetime overview',
              comment: 'your overall tracking summary',
              rows: [
                ('days tracked', '${overview.daysTracked} days'),
                ('avg completion', '${(overview.avgCompletion * 100).round()}%'),
                ('daily goal met', '${overview.dailyGoalMetDays} days'),
                ('total completions', '${overview.totalCompletions}'),
              ],
            ),
            _StatSection(
              title: 'streaks',
              comment: 'consecutive days hitting your daily goal',
              rows: [
                ('current streak', '${overview.goalStreak.current} days'),
                ('best streak', '${overview.goalStreak.best} days'),
                if (overview.topHabitTitle != null)
                  ('top habit streak',
                      '${overview.topHabitTitle} — ${overview.topHabitStreak} days'),
              ],
            ),
            Text('data window', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 3),
            Text('// choose a preset, or pick a custom range',
                style: AppTheme.comment.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in [DataWindow.d7, DataWindow.d30, DataWindow.d90, DataWindow.all])
                  _WindowChip(
                    label: w.label,
                    selected: window == w,
                    onTap: () => controller.setStatsWindow(w),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _StatSection(
              title: 'completion rates [${window.label}]',
              comment: 'how often you complete scheduled habits',
              rows: [
                ('this period', '${(overview.thisWindowCompletion * 100).round()}%'),
                ('perfect days',
                    '${overview.perfectDays}/${overview.totalDaysInWindow}'),
                ('weekday avg', '${(overview.weekdayAvg * 100).round()}%'),
                ('weekend avg', '${(overview.weekendAvg * 100).round()}%'),
              ],
            ),
            Text('day of week [${window.label}]', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 3),
            Text('// completion rates broken down by day',
                style: AppTheme.comment.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            for (var i = 0; i < 7; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(AppText.weekdayShort[i].toLowerCase(),
                          style: const TextStyle(
                              fontFamilyFallback: AppTheme.mono,
                              color: AppTheme.textMid,
                              fontSize: 11)),
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
            if (overview.bestWeekday != null && overview.worstWeekday != null) ...[
              const SizedBox(height: 6),
              Text(
                'best day: ${AppText.weekdayShort[overview.bestWeekday!].toLowerCase()} '
                '(${(overview.dayOfWeekRates[overview.bestWeekday!] * 100).round()}%)   '
                'worst day: ${AppText.weekdayShort[overview.worstWeekday!].toLowerCase()} '
                '(${(overview.dayOfWeekRates[overview.worstWeekday!] * 100).round()}%)',
                style: AppTheme.comment.copyWith(fontSize: 10.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.amber.withValues(alpha: 0.18) : AppTheme.cardInset,
          border: Border.all(color: selected ? AppTheme.amber : AppTheme.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text('[$label]',
            style: TextStyle(
                fontFamilyFallback: AppTheme.mono,
                fontSize: 11,
                color: selected ? AppTheme.amberBright : AppTheme.textMid)),
      ),
    );
  }
}

class _StatSection extends StatelessWidget {
  const _StatSection({required this.title, required this.comment, required this.rows});

  final String title;
  final String comment;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 3),
          Text('// $comment', style: AppTheme.comment.copyWith(fontSize: 11)),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('$label: ',
                      style: const TextStyle(
                          fontFamilyFallback: AppTheme.mono,
                          color: AppTheme.textMid,
                          fontSize: 12)),
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            fontFamilyFallback: AppTheme.mono,
                            color: AppTheme.textHigh,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
