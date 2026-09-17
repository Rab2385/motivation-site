import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../util/dates.dart';

/// Compact month calendar: `< august 2026 >` header, Mo..Su day grid, the
/// current day boxed, days with completions tinted amber.
class MiniCalendar extends StatefulWidget {
  const MiniCalendar({super.key, required this.controller, this.onSelectDay});

  final MotivationController controller;
  final ValueChanged<DateTime>? onSelectDay;

  @override
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late DateTime _month = DateTime(widget.controller.today.year, widget.controller.today.month);

  @override
  Widget build(BuildContext context) {
    final today = widget.controller.today;
    final firstOfMonth = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1..Sun=7

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () =>
                  setState(() => _month = DateTime(_month.year, _month.month - 1)),
              icon: const Icon(Icons.chevron_left, size: 16, color: AppTheme.textMid),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${AppText.monthLong[_month.month - 1].toLowerCase()} ${_month.year}',
                  style: const TextStyle(
                      fontFamilyFallback: AppTheme.mono,
                      color: AppTheme.textHigh,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () =>
                  setState(() => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMid),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final label in AppText.weekdayShort)
              Expanded(
                child: Center(
                  child: Text(label.substring(0, 2).toLowerCase(),
                      style: const TextStyle(color: AppTheme.textLow, fontSize: 9.5)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        for (var row = 0; row < ((leadingBlanks + daysInMonth) / 7).ceil(); row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _dayCell(row * 7 + col - leadingBlanks, today),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayCell(int dayNumber, DateTime today) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    if (dayNumber < 0 || dayNumber >= daysInMonth) {
      return const SizedBox(height: 22);
    }
    final date = DateTime(_month.year, _month.month, dayNumber + 1);
    final isToday = isSameDay(date, today);
    final done = widget.controller.completedCountForDate(date) > 0;

    return GestureDetector(
      onTap: () => widget.onSelectDay?.call(date),
      child: Container(
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isToday
              ? AppTheme.amber.withValues(alpha: 0.18)
              : (done ? AppTheme.amber.withValues(alpha: 0.08) : null),
          border: isToday ? Border.all(color: AppTheme.amber) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          isToday ? '*${dayNumber + 1}' : '${dayNumber + 1}',
          style: TextStyle(
            fontFamilyFallback: AppTheme.mono,
            fontSize: 10.5,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: isToday ? AppTheme.amberBright : AppTheme.textMid,
          ),
        ),
      ),
    );
  }
}
