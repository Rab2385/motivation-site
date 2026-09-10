import 'package:flutter/material.dart';

import '../domain/achievements.dart';
import '../l10n/app_text.dart';
import '../l10n/quotes.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../theme/atmosphere.dart';
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
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination(AppText.dashboard, Icons.explore_outlined, Icons.explore),
    _Destination(AppText.today, Icons.bolt_outlined, Icons.bolt),
    _Destination(AppText.weekPlanning, Icons.calendar_month_outlined,
        Icons.calendar_month),
    _Destination(AppText.habits, Icons.autorenew_outlined, Icons.autorenew),
    _Destination(AppText.rewards, Icons.card_giftcard_outlined,
        Icons.card_giftcard),
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
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  destinations: _destinations,
                  selectedIndex: _index,
                  onSelect: _select,
                  extended: constraints.maxWidth >= 1240,
                  showAtmosphere: widget.controller.showAtmosphere,
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.extended,
    required this.showAtmosphere,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final void Function(int) onSelect;
  final bool extended;
  final bool showAtmosphere;

  @override
  Widget build(BuildContext context) {
    final width = extended ? 236.0 : 76.0;
    return Container(
      width: width,
      color: AppTheme.bgRaised,
      child: Stack(
        children: [
          if (showAtmosphere)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 220,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.7],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: const AtmosphereBackground(
                    seed: 19, glowAlignment: Alignment(0, 1.2)),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(extended ? 18 : 0, 20, 0, 18),
                child: Row(
                  mainAxisAlignment: extended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const CompassMark(size: 30),
                    if (extended) ...[
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppText.appName,
                              style: TextStyle(
                                fontFamilyFallback: AppTheme.serif,
                                fontSize: 20,
                                color: AppTheme.textHigh,
                                fontWeight: FontWeight.w600,
                              )),
                          const Text(AppText.appTagline,
                              style: TextStyle(
                                  color: AppTheme.textLow,
                                  fontSize: 11,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: extended ? 10 : 8),
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      _NavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        extended: extended,
                        onTap: () => onSelect(i),
                      ),
                  ],
                ),
              ),
              if (extended)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                  child: Text(
                    '„${quoteOfTheDay(DateTime.now(), slot: 5)}"',
                    style: AppTheme.quote.copyWith(fontSize: 11.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppTheme.gold.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: extended ? 12 : 0, vertical: 11),
            child: Row(
              mainAxisAlignment: extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  selected
                      ? destination.selectedIcon
                      : destination.icon,
                  size: 20,
                  color: selected ? AppTheme.goldBright : AppTheme.textLow,
                ),
                if (extended) ...[
                  const SizedBox(width: 12),
                  Text(
                    destination.label,
                    style: TextStyle(
                      color: selected ? AppTheme.goldBright : AppTheme.textMid,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
