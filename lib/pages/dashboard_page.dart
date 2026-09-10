import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../l10n/quotes.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../theme/atmosphere.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/proposal_review_sheet.dart';
import '../widgets/quest_tile.dart';
import '../widgets/reward_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.onOpenTab,
  });

  final MotivationController controller;
  final void Function(int index) onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final wide = MediaQuery.sizeOf(context).width >= 1040;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  _GreetingHeader(controller: controller),
                  const SizedBox(height: 16),
                  _HeroCard(controller: controller),
                  const SizedBox(height: 16),
                  if (controller.pendingProposals.isNotEmpty) ...[
                    _ProposalBanner(controller: controller),
                    const SizedBox(height: 16),
                  ],
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _TodayTasksCard(
                              controller: controller, onOpenTab: onOpenTab),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _RewardsCard(
                              controller: controller, onOpenTab: onOpenTab),
                        ),
                      ],
                    )
                  else ...[
                    _TodayTasksCard(controller: controller, onOpenTab: onOpenTab),
                    const SizedBox(height: 16),
                    _RewardsCard(controller: controller, onOpenTab: onOpenTab),
                  ],
                  const SizedBox(height: 16),
                  _WeekProgressCard(controller: controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final showAside = MediaQuery.sizeOf(context).width >= 680;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greetingFor(now),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 30, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Disziplin heute. Ein stärkeres Ich morgen.',
                  style: TextStyle(color: AppTheme.textMid)),
            ],
          ),
        ),
        if (showAside) ...[
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.textMid),
                    const SizedBox(width: 6),
                    Text(longDate(now),
                        style: const TextStyle(
                            color: AppTheme.textMid, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '„${quoteOfTheDay(now, slot: 1)}"',
                  textAlign: TextAlign.right,
                  style: AppTheme.quote.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.levelProgress;
    final stats = controller.statsSnapshot;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
          color: AppTheme.card,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.white],
                      stops: [0.0, 0.6],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: const AtmosphereBackground(
                        glowAlignment: Alignment(0.5, -0.1)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LevelRing(progress: progress),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppText.continueJourney,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontSize: 20)),
                            const SizedBox(height: 12),
                            XpBar(progress: progress),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('XP ${progress.xpIntoLevel} / '
                                    '${progress.xpForThisLevel}',
                                    style: const TextStyle(
                                        color: AppTheme.goldBright,
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text(
                                  '${AppText.nextLevelIn}'
                                  '${progress.xpToNextLevel} XP',
                                  style: const TextStyle(
                                      color: AppTheme.textMid, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatChip(
                        icon: Icons.local_fire_department,
                        iconColor: AppTheme.streakAccent,
                        label: 'Streak: ${stats.bestCurrentStreak} Tage',
                      ),
                      StatChip(
                        icon: Icons.emoji_events_outlined,
                        label:
                            '${stats.totalCompletions}${AppText.totalTasksDone}',
                      ),
                      const StatChip(
                        icon: Icons.star_border,
                        label: AppText.youreDoingGreat,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalBanner extends StatelessWidget {
  const _ProposalBanner({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final proposals = controller.pendingProposals;
    return Card(
      color: AppTheme.gold.withValues(alpha: 0.10),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: AppTheme.goldBright),
        title: Text('${proposals.length} ${AppText.assistantProposal}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            showProposalReviewSheet(context, controller, proposals.first),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.trailing});
  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppTheme.goldBright),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: Align(alignment: Alignment.centerRight, child: trailing!)),
        ],
      ],
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  const _TodayTasksCard({required this.controller, required this.onOpenTab});
  final MotivationController controller;
  final void Function(int index) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final quests = controller.todaysQuests;
    final done = quests.where((q) => q.isCompleted).length;
    final earned = controller.completedXpForDate(controller.today);
    final open = quests.where((q) => q.isOpen).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.checklist_rtl,
              title: AppText.todaysTasks,
              trailing: Text('$done von ${quests.length}${AppText.ofTasksDone}',
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 12.5)),
            ),
            const SizedBox(height: 6),
            if (quests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Text(AppText.noQuestsToday,
                        style: TextStyle(color: AppTheme.textMid)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => onOpenTab(2),
                      child: const Text(AppText.planYourWeek),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < quests.length; i++)
                QuestTile(
                  controller: controller,
                  occurrence: quests[i],
                  flat: true,
                  showDivider: i < quests.length - 1,
                ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardInset,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 16, color: AppTheme.goldBright),
                  const SizedBox(width: 8),
                  const Text(AppText.earnedToday,
                      style: TextStyle(color: AppTheme.textMid, fontSize: 12.5)),
                  Text('$earned XP',
                      style: const TextStyle(
                          color: AppTheme.goldBright, fontWeight: FontWeight.w800,
                          fontSize: 12.5)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      quests.isEmpty
                          ? ''
                          : (open == 0
                              ? AppText.perfectDayReached
                              : (open == 1
                                  ? AppText.oneTaskToPerfect
                                  : 'Noch $open Aufgaben bis zur perfekten Tagesbilanz!')),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.controller, required this.onOpenTab});
  final MotivationController controller;
  final void Function(int index) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final rewards = controller.rewards.take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.card_giftcard,
              title: AppText.unlockedRewards,
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppText.allRewards,
                onPressed: () => onOpenTab(4),
                icon: const Icon(Icons.arrow_forward,
                    size: 15, color: AppTheme.goldBright),
              ),
            ),
            const SizedBox(height: 12),
            if (rewards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Noch keine Belohnungen angelegt.',
                    style: TextStyle(color: AppTheme.textMid)),
              )
            else
              for (final reward in rewards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RewardCard(controller: controller, reward: reward),
                ),
          ],
        ),
      ),
    );
  }
}

class _WeekProgressCard extends StatelessWidget {
  const _WeekProgressCard({required this.controller});
  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    final days = controller.weekDays(0);
    final counts = [
      for (final day in days) controller.completedCountForDate(day),
    ];
    final todayIndex = DateTime.now().weekday - 1;
    final thisWeek = controller.weekTotals(0);
    final lastWeek = controller.weekTotals(-1);
    final stats = controller.statsSnapshot;

    String delta(int now, int before) {
      if (before == 0) return now > 0 ? '+100%' : '±0%';
      final pct = ((now - before) / before * 100).round();
      return '${pct >= 0 ? '+' : ''}$pct%';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.bar_chart,
              title: AppText.weekProgress,
              trailing: Text(
                '${days.first.day}.${days.first.month}. – '
                '${days.last.day}.${days.last.month}.',
                style: const TextStyle(color: AppTheme.textMid, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 14),
            WeekBars(values: counts, highlightIndex: todayIndex),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final cards = [
                MiniStatCard(
                  icon: Icons.check_circle_outline,
                  value: '${thisWeek.tasks}',
                  label: AppText.doneTasks,
                  delta: delta(thisWeek.tasks, lastWeek.tasks),
                ),
                MiniStatCard(
                  icon: Icons.bolt,
                  value: '${thisWeek.xp}',
                  label: AppText.collectedXp,
                  delta: delta(thisWeek.xp, lastWeek.xp),
                ),
                MiniStatCard(
                  icon: Icons.local_fire_department,
                  iconColor: AppTheme.streakAccent,
                  value: '${stats.longestStreakEver}',
                  label: AppText.longestStreak,
                ),
              ];
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
