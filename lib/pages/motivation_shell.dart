import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/achievements.dart';
import '../l10n/app_text.dart';
import '../state/home_nav_state.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/terminal_widgets.dart';
import 'habits_home_page.dart';
import 'help_page.dart';
import 'profile_page.dart';
import 'stats_page.dart';
import 'system_page.dart';
import 'week_plan_page.dart';

class MotivationShell extends StatefulWidget {
  const MotivationShell({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<MotivationShell> createState() => _MotivationShellState();
}

class _MotivationShellState extends State<MotivationShell> {
  int _index = 0;
  final HomeNavState _nav = HomeNavState();
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _keyboardFocus.dispose();
    _nav.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.controller.takePerfectToast()) {
      showQuestToast(
        context,
        title: AppText.perfectDayBonusToast,
        subtitle: '+${widget.controller.perfectDayBonus} XP bonus',
        icon: Icons.wb_sunny,
        accent: AppTheme.amberBright,
      );
    }
    final achievements = {for (final a in achievementCatalogue) a.id: a};
    for (final id in widget.controller.takeAchievementToasts()) {
      final achievement = achievements[id];
      if (achievement == null) continue;
      showQuestToast(
        context,
        title: 'Achievement unlocked',
        subtitle: achievement.title,
        icon: achievement.icon,
        accent: AppTheme.amberBright,
      );
    }
    for (final reward in widget.controller.takeRewardToasts()) {
      showQuestToast(
        context,
        title: 'Reward unlocked',
        subtitle: reward.title,
        icon: reward.icon,
        accent: AppTheme.amberBright,
      );
    }
  }

  Widget _pageFor(int index) {
    final controller = widget.controller;
    switch (index) {
      case 0:
        return HabitsHomePage(controller: controller, nav: _nav);
      case 1:
        return StatsPage(controller: controller);
      case 2:
        return ProfilePage(controller: controller);
      case 3:
        return SystemPage(controller: controller);
      default:
        return const HelpPage();
    }
  }

  void _select(int index) => setState(() => _index = index);

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      _nav.shiftDay(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _nav.shiftDay(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1) {
      _select(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2) {
      _select(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3) {
      _select(2);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit4) {
      _select(3);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit5) {
      _select(4);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA) {
      showTaskEditorSheet(context, widget.controller, date: _nav.date);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.question) {
      _select(4);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final page = _pageFor(_index);

        final body = wide
            ? Column(
                children: [
                  _TopBar(
                    selected: _index,
                    onSelect: _select,
                    onOpenPlanner: () => _openPlanner(context),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: page,
                    ),
                  ),
                  const KeyboardHintBar(hints: [
                    ('?', 'help'),
                    ('←→', 'day'),
                    ('1-5', 'menu'),
                    ('a', 'add habit'),
                  ]),
                ],
              )
            : Column(
                children: [
                  _MobileTopBar(
                    controller: widget.controller,
                    onOpenPlanner: () => _openPlanner(context),
                  ),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 8), child: page)),
                ],
              );

        final scaffold = Scaffold(
          body: body,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index > 2 ? 0 : _index,
                  onDestinationSelected: _select,
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.checklist_outlined),
                        selectedIcon: Icon(Icons.checklist),
                        label: AppText.habits),
                    NavigationDestination(
                        icon: Icon(Icons.insights_outlined),
                        selectedIcon: Icon(Icons.insights),
                        label: AppText.statistics),
                    NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: AppText.profile),
                  ],
                ),
        );

        if (!wide) return scaffold;

        return Focus(
          focusNode: _keyboardFocus,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: scaffold,
        );
      },
    );
  }

  void _openPlanner(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => WeekPlanPage(controller: widget.controller),
    ));
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.selected, required this.onSelect, required this.onOpenPlanner});

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenPlanner;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgRaised,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.amber),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Q',
                style: TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    color: AppTheme.amberBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 8),
          const Text(AppText.appName,
              style: TextStyle(
                  fontFamilyFallback: AppTheme.mono,
                  color: AppTheme.textHigh,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(width: 6),
          const Text('[beta]', style: TextStyle(color: AppTheme.textLow, fontSize: 11)),
          const SizedBox(width: 28),
          for (var i = 0; i < 5; i++) _NavLabel(index: i, selected: selected == i, onTap: onSelect),
          const Spacer(),
          IconButton(
            tooltip: 'weekly planner',
            onPressed: onOpenPlanner,
            icon: const Icon(Icons.calendar_month_outlined, size: 19, color: AppTheme.textMid),
          ),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel({required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  static const _labels = [
    AppText.habits,
    AppText.statistics,
    AppText.profile,
    AppText.settings,
    AppText.help,
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_labels[index]} ▾',
              style: TextStyle(
                fontFamilyFallback: AppTheme.mono,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppTheme.amberBright : AppTheme.textMid,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2,
              width: 26,
              color: selected ? AppTheme.amber : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.controller, required this.onOpenPlanner});

  final MotivationController controller;
  final VoidCallback onOpenPlanner;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
        child: Row(
          children: [
            Text('[h] ${AppText.appName}',
                style: const TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    color: AppTheme.textHigh,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const Spacer(),
            IconButton(
              onPressed: onOpenPlanner,
              icon: const Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.textMid),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SystemPage(controller: controller))),
              icon: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textMid),
            ),
          ],
        ),
      ),
    );
  }
}
