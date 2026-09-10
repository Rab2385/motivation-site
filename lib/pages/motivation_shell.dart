import 'package:flutter/material.dart';

import '../domain/achievements.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import 'achievements_page.dart';
import 'dashboard_page.dart';
import 'habits_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'today_page.dart';
import 'week_plan_page.dart';

class MotivationShell extends StatefulWidget {
  const MotivationShell({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<MotivationShell> createState() => _MotivationShellState();
}

class _MotivationShellState extends State<MotivationShell> {
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination(AppText.dashboard, Icons.dashboard_outlined, Icons.dashboard),
    _Destination(AppText.today, Icons.bolt_outlined, Icons.bolt),
    _Destination(AppText.weekPlanning, Icons.calendar_month_outlined,
        Icons.calendar_month),
    _Destination(AppText.habits, Icons.autorenew_outlined, Icons.autorenew),
    _Destination(AppText.statistics, Icons.insights_outlined, Icons.insights),
    _Destination(
        AppText.achievements, Icons.emoji_events_outlined, Icons.emoji_events),
    _Destination(AppText.settings, Icons.settings_outlined, Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final toasts = widget.controller.takeAchievementToasts();
    if (toasts.isEmpty || !mounted) return;
    final catalogue = {for (final a in achievementCatalogue) a.id: a};
    for (final id in toasts) {
      final achievement = catalogue[id];
      if (achievement == null) continue;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(achievement.icon, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(child: Text('Erfolg freigeschaltet: ${achievement.title}')),
            ],
          ),
        ),
      );
    }
  }

  Widget _pageFor(int index) {
    final controller = widget.controller;
    switch (index) {
      case 0:
        return DashboardPage(controller: controller, onOpenTab: _select);
      case 1:
        return TodayPage(controller: controller);
      case 2:
        return WeekPlanPage(controller: controller);
      case 3:
        return HabitsPage(controller: controller);
      case 4:
        return StatisticsPage(controller: controller);
      case 5:
        return AchievementsPage(controller: controller);
      default:
        return SettingsPage(controller: controller);
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final page = _pageFor(_index);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 1180,
                  minExtendedWidth: 210,
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Icon(Icons.local_fire_department, size: 28),
                  ),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
