import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/reward.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

/// Reward tile shared by the dashboard and the Belohnungen page. Shows an
/// "Einlösen" button when unlocked, a lock + level-progress bar otherwise.
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.controller,
    required this.reward,
    this.onEdit,
  });

  final MotivationController controller;
  final Reward reward;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final level = controller.levelProgress.level;
    final unlocked = reward.isUnlocked(level);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardInset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              unlocked ? AppTheme.gold.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppTheme.gold.withValues(alpha: 0.16)
                      : const Color(0xFF1B2740),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? reward.icon : Icons.lock_outline,
                  size: 18,
                  color: unlocked ? AppTheme.goldBright : AppTheme.textLow,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined,
                      size: 15, color: AppTheme.textLow),
                  onPressed: onEdit,
                )
              else if (unlocked)
                const Icon(Icons.check_circle,
                    size: 18, color: AppTheme.successAccent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reward.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: unlocked ? AppTheme.textHigh : AppTheme.textMid),
          ),
          const SizedBox(height: 3),
          if (unlocked)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 13, color: AppTheme.successAccent),
                const SizedBox(width: 4),
                Text(AppText.unlockedLabel,
                    style: const TextStyle(
                        color: AppTheme.successAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            )
          else
            Text('Level ${reward.requiredLevel}${AppText.levelRequired}',
                style: const TextStyle(color: AppTheme.textMid, fontSize: 12)),
          if (unlocked && reward.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(reward.description,
                style: const TextStyle(color: AppTheme.textLow, fontSize: 11.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (reward.redeemedCount > 0) ...[
            const SizedBox(height: 4),
            Text('${reward.redeemedCount}${AppText.redeemedTimes}',
                style: const TextStyle(color: AppTheme.textLow, fontSize: 11)),
          ],
          const SizedBox(height: 12),
          if (unlocked)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final ok = await controller.redeemReward(reward.id);
                  if (ok && context.mounted) {
                    showQuestToast(
                      context,
                      title: AppText.rewardRedeemed,
                      subtitle: '${reward.title} · ${AppText.enjoyIt}',
                      icon: Icons.card_giftcard,
                      accent: AppTheme.goldBright,
                    );
                  }
                },
                child: const Text(AppText.redeem),
              ),
            )
          else
            _LockProgress(
                controller: controller, requiredLevel: reward.requiredLevel),
        ],
      ),
    );
  }
}

class _LockProgress extends StatelessWidget {
  const _LockProgress({required this.controller, required this.requiredLevel});
  final MotivationController controller;
  final int requiredLevel;

  @override
  Widget build(BuildContext context) {
    final progress = controller.levelProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFF1B2740),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF3E5C8A)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${progress.xpIntoLevel} / ${progress.xpForThisLevel} XP · '
          'Level ${progress.level}/$requiredLevel',
          style: const TextStyle(color: AppTheme.textLow, fontSize: 11),
        ),
      ],
    );
  }
}
