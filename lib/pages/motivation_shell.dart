import 'package:flutter/material.dart';

import '../domain/achievements.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'achievements_page.dart';
import 'dashboard_page.dart';
import 'habits_page.dart';
import 'rewards_page.dart';
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
  int _index = 3;

  static const _destinations = <_Destination>[
    _Destination(AppText.dashboard, Icons.explore_outlined, Icons.explore),
    _Destination(AppText.today, Icons.bolt_outlined, Icons.bolt),
    _Destination(
      AppText.weekPlanning,
      Icons.calendar_month_outlined,
      Icons.calendar_month,
    ),
    _Destination(AppText.habits, Icons.autorenew_outlined, Icons.autorenew),
    _Destination(
      AppText.rewards,
      Icons.card_giftcard_outlined,
      Icons.card_giftcard,
    ),
    _Destination(AppText.statistics, Icons.insights_outlined, Icons.insights),
    _Destination(
      AppText.achievements,
      Icons.emoji_events_outlined,
      Icons.emoji_events,
    ),
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
    if (!mounted) return;
    setState(() {});
    if (widget.controller.takePerfectToast()) {
      showQuestToast(
        context,
        title: AppText.perfectDayBonusToast,
        subtitle: '+${widget.controller.perfectDayBonus} XP Bonus',
        icon: Icons.wb_sunny,
        accent: AppTheme.goldBright,
      );
    }
    final achievements = {for (final a in achievementCatalogue) a.id: a};
    for (final id in widget.controller.takeAchievementToasts()) {
      final achievement = achievements[id];
      if (achievement == null) continue;
      showQuestToast(
        context,
        title: 'Erfolg freigeschaltet',
        subtitle: achievement.title,
        icon: achievement.icon,
        accent: AppTheme.goldBright,
      );
    }
    for (final reward in widget.controller.takeRewardToasts()) {
      showQuestToast(
        context,
        title: 'Belohnung freigeschaltet',
        subtitle: reward.title,
        icon: reward.icon,
        accent: AppTheme.goldBright,
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
        return RewardsPage(controller: controller);
      case 5:
        return StatisticsPage(controller: controller);
      case 6:
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
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF1B77C), Color(0xFF75AEEB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Material(color: AppTheme.bg, child: page),
                    ),
                  ),
                ),
              ),
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
