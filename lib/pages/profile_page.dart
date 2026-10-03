import 'package:flutter/material.dart';

import '../domain/achievements.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/terminal_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.levelProgress;
        final achievements = achievementCatalogue;
        final unlocks = controller.achievementUnlocks;
        final unlockedCount = achievements
            .where((a) => unlocks.containsKey(a.id))
            .length;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TerminalPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TerminalHeader('profile'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.amber,
                                width: 1.4,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${progress.level}',
                              style: const TextStyle(
                                fontFamilyFallback: AppTheme.mono,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.amberBright,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'level ${progress.level}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                BarProgress(
                                  fraction: progress.fraction,
                                  label:
                                      '${progress.xpIntoLevel}/${progress.xpForThisLevel} xp',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TerminalPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TerminalHeader(
                        'achievements',
                        comment:
                            '$unlockedCount / ${achievements.length} unlocked',
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth > 640
                              ? 3
                              : (constraints.maxWidth > 400 ? 2 : 1);
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.6,
                            children: [
                              for (final achievement in achievements)
                                _AchievementRow(
                                  achievement: achievement,
                                  unlockedAt: unlocks[achievement.id],
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.unlockedAt});

  final AchievementDefinition achievement;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final unlocked = unlockedAt != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        border: Border.all(
          color: unlocked
              ? AppTheme.amber.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            achievement.icon,
            size: 18,
            color: unlocked ? AppTheme.amberBright : AppTheme.textLow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontFamilyFallback: AppTheme.mono,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unlocked ? AppTheme.textHigh : AppTheme.textMid,
                  ),
                ),
                Text(
                  achievement.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textLow,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(
              Icons.check_circle,
              size: 15,
              color: AppTheme.successAccent,
            ),
        ],
      ),
    );
  }
}
