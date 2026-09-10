import 'package:flutter/material.dart';

import '../domain/achievements.dart';
import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.achievements,
      listenable: controller,
      builder: (context) {
        final unlocks = controller.achievementUnlocks;
        final catalogue = achievementCatalogue;
        final unlockedCount =
            catalogue.where((a) => unlocks.containsKey(a.id)).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text('$unlockedCount / ${catalogue.length} freigeschaltet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final achievement in catalogue)
                  _AchievementCard(
                    icon: achievement.icon,
                    title: achievement.title,
                    description: achievement.description,
                    unlockedAt: unlocks[achievement.id],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlockedAt,
  });

  final IconData icon;
  final String title;
  final String description;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final unlocked = unlockedAt != null;
    final theme = Theme.of(context);
    return Card(
      child: Opacity(
        opacity: unlocked ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: unlocked ? AppTheme.xpAccent : theme.hintColor,
                  size: 26),
              const Spacer(),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
