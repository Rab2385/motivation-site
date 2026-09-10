import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../l10n/quotes.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/reward_card.dart';
import '../widgets/reward_editor_sheet.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppText.rewards,
      listenable: controller,
      maxContentWidth: 900,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRewardEditorSheet(context, controller),
        icon: const Icon(Icons.add),
        label: const Text(AppText.newReward),
      ),
      builder: (context) {
        final rewards = controller.rewards;
        final level = controller.levelProgress.level;
        final unlocked = rewards.where((r) => r.isUnlocked(level)).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Row(
              children: [
                Text('$unlocked / ${rewards.length} freigeschaltet',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('Level $level',
                    style: const TextStyle(color: AppTheme.goldBright)),
              ],
            ),
            const SizedBox(height: 8),
            Text('„${quoteOfTheDay(DateTime.now(), slot: 3)}"',
                style: AppTheme.quote),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth > 620 ? 3 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  for (final reward in rewards)
                    RewardCard(
                      controller: controller,
                      reward: reward,
                      onEdit: () => showRewardEditorSheet(context, controller,
                          existing: reward),
                    ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}
