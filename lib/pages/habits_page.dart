import 'package:flutter/material.dart';

import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../state/motivation_controller.dart';

enum _HabitFilter { alle, taeglich, woechentlich, einmalig, inaktiv }

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  _HabitFilter _filter = _HabitFilter.alle;

  MotivationController get controller => widget.controller;

  bool _isDaily(TaskDefinition d) =>
      d.recurrence.kind == RecurrenceKind.fixedWeekdays &&
      d.recurrence.weekdays.length == 7;

  bool _isWeekly(TaskDefinition d) =>
      d.recurrence.kind == RecurrenceKind.timesPerWeek ||
      (d.recurrence.kind == RecurrenceKind.fixedWeekdays &&
          d.recurrence.weekdays.length < 7);

  List<_HabitRowData> _filteredTasks() {
    final all = controller.definitions;
    final active = all.where((d) => !d.isArchived && !d.isPaused).toList();
    final inactive = all.where((d) => d.isArchived || d.isPaused).toList();

    switch (_filter) {
      case _HabitFilter.alle:
        return [
          for (final d in active)
            _HabitRowData(
              title: d.title,
              subtitle: controller.categoryById(d.categoryId).name,
              xp: d.xp,
            ),
        ];
      case _HabitFilter.taeglich:
        return [
          for (final d in active.where(_isDaily))
            _HabitRowData(
              title: d.title,
              subtitle: controller.categoryById(d.categoryId).name,
              xp: d.xp,
            ),
        ];
      case _HabitFilter.woechentlich:
        return [
          for (final d in active.where(_isWeekly))
            _HabitRowData(
              title: d.title,
              subtitle: controller.categoryById(d.categoryId).name,
              xp: d.xp,
            ),
        ];
      case _HabitFilter.inaktiv:
        return [
          for (final d in inactive)
            _HabitRowData(
              title: d.title,
              subtitle: controller.categoryById(d.categoryId).name,
              xp: d.xp,
            ),
        ];
      case _HabitFilter.einmalig:
        return [
          for (final o in controller.upcomingOneOffs)
            _HabitRowData(
              title: o.title,
              subtitle: controller.categoryById(o.categoryId).name,
              xp: o.xp,
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredTasks();
    final isCompact = MediaQuery.sizeOf(context).width < 820;
    final totalXp = rows.fold<int>(0, (sum, item) => sum + item.xp);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1727),
                  borderRadius: BorderRadius.circular(isCompact ? 26 : 30),
                  border: Border.all(color: const Color(0xFF23324A), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NightHeader(isCompact: isCompact),
                      const SizedBox(height: 18),
                      _LevelCard(
                        level: 1,
                        currentXp: 0,
                        targetXp: 100,
                        streak: 0,
                        completed: 0,
                        total: rows.length,
                        isCompact: isCompact,
                      ),
                      const SizedBox(height: 18),
                      if (!isCompact)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _TaskListPanel(
                                rows: rows,
                                filter: _filter,
                                totalXp: totalXp,
                                onFilterChanged: (value) =>
                                    setState(() => _filter = value),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(flex: 2, child: _RewardPanel()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _TaskListPanel(
                              rows: rows,
                              filter: _filter,
                              totalXp: totalXp,
                              onFilterChanged: (value) =>
                                  setState(() => _filter = value),
                            ),
                            const SizedBox(height: 18),
                            _RewardPanel(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitRowData {
  const _HabitRowData({
    required this.title,
    required this.subtitle,
    required this.xp,
  });

  final String title;
  final String subtitle;
  final int xp;
}

class _NightHeader extends StatelessWidget {
  const _NightHeader({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gute Nacht!',
                style: TextStyle(
                  color: const Color(0xFFEEF4FF),
                  fontSize: isCompact ? 22 : 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bleib dran. Große Ziele brauchen Zeit.',
                style: TextStyle(
                  color: const Color(0xFF9AA6BC),
                  fontSize: isCompact ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Donnerstag, 17. September 2026',
              style: TextStyle(
                color: const Color(0xFFEEF4FF),
                fontSize: isCompact ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '„Disziplin heute. Ein stärkeres Ich morgen.“',
              style: TextStyle(
                color: const Color(0xFF8EA2BE),
                fontSize: isCompact ? 8.5 : 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.currentXp,
    required this.targetXp,
    required this.streak,
    required this.completed,
    required this.total,
    required this.isCompact,
  });

  final int level;
  final int currentXp;
  final int targetXp;
  final int streak;
  final int completed;
  final int total;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final progress = (currentXp / targetXp).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101C2E),
        border: Border.all(color: const Color(0xFF243450)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 42 : 46,
                height: isCompact ? 42 : 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1220),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFE7C46A), width: 2),
                  ),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE7C46A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(
                        color: const Color(0xFFEEF4FF),
                        fontSize: isCompact ? 20 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Weiter auf deiner Reise',
                      style: TextStyle(
                        color: const Color(0xFF9AA6BC),
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$currentXp / $targetXp XP',
                  style: const TextStyle(
                    color: Color(0xFFF1D99A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                'Nächstes Level in ${targetXp - currentXp} XP',
                style: const TextStyle(
                  color: Color(0xFF9AA6BC),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF121F31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2BC5C),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: '⏱ 0 Tage Streak', selected: streak > 0),
              _Pill(label: '✓ $completed erledigt', selected: completed > 0),
              _Pill(label: '🏆 $total Aufgaben', selected: total > 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1A2940) : const Color(0xFF0F1B2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2C3E57)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE9F1FF),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskListPanel extends StatelessWidget {
  const _TaskListPanel({
    required this.rows,
    required this.totalXp,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<_HabitRowData> rows;
  final int totalXp;
  final _HabitFilter filter;
  final void Function(_HabitFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      _HabitFilter.alle,
      _HabitFilter.taeglich,
      _HabitFilter.woechentlich,
      _HabitFilter.einmalig,
      _HabitFilter.inaktiv,
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101C2E),
        border: Border.all(color: const Color(0xFF243450)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: Color(0xFFE7C46A), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Heutige Aufgaben',
                  style: TextStyle(
                    color: Color(0xFFEEF4FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '0 von 7 Aufgaben erledigt',
                style: const TextStyle(
                  color: Color(0xFF9AA6BC),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in filters)
                GestureDetector(
                  onTap: () => onFilterChanged(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: filter == item ? const Color(0xFF1C2C40) : const Color(0xFF0F1B2A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: filter == item ? const Color(0xFF3A4F6E) : const Color(0xFF213250),
                      ),
                    ),
                    child: Text(
                      switch (item) {
                        _HabitFilter.alle => 'Alle',
                        _HabitFilter.taeglich => 'Täglich',
                        _HabitFilter.woechentlich => 'Wöchentlich',
                        _HabitFilter.einmalig => 'Einmalig',
                        _HabitFilter.inaktiv => 'Inaktiv',
                      },
                      style: TextStyle(
                        color: filter == item ? const Color(0xFFF1D99A) : const Color(0xFF9AA6BC),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.take(7).map((task) => _HabitRow(task: task)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFE7C46A)),
              const SizedBox(width: 6),
              const Text(
                'Heute verdient:',
                style: TextStyle(color: Color(0xFF9AA6BC), fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$totalXp XP',
                style: const TextStyle(
                  color: Color(0xFFE7C46A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.task});

  final _HabitRowData task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFB9C5D9), width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Color(0xFFEEF4FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  task.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7F8FAA),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${task.xp} XP',
            style: const TextStyle(
              color: Color(0xFFE7C46A),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel();

  @override
  Widget build(BuildContext context) {
    final rewards = [
      _RewardCard(
        title: 'Kaffeepause',
        subtitle: 'Freigeschaltet',
        accent: const Color(0xFF6DD69A),
        isActive: true,
      ),
      _RewardCard(
        title: '30 Minuten Gaming-Zeit',
        subtitle: 'Level 3 erforderlich',
        accent: const Color(0xFF7DA4FF),
        isActive: false,
      ),
      _RewardCard(
        title: 'Eine Folge deiner Serie',
        subtitle: 'Level 5 erforderlich',
        accent: const Color(0xFFB2A1FF),
        isActive: false,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101C2E),
        border: Border.all(color: const Color(0xFF243450)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFE7C46A), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Freigeschaltete Belohnungen',
                  style: TextStyle(
                    color: Color(0xFFEEF4FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF9AA6BC)),
            ],
          ),
          const SizedBox(height: 12),
          ...rewards,
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1625),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF243450)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_cafe_rounded,
              color: accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEEF4FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9AA6BC),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5FC989) : const Color(0xFF2A384D),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
