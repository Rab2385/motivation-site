import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../state/motivation_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/reward_card.dart';
import '../widgets/reward_editor_sheet.dart';

enum _RewardFilter { alle, freigeschaltet, gesperrt }

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key, required this.controller});

  final MotivationController controller;

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  _RewardFilter _filter = _RewardFilter.alle;

  MotivationController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final level = controller.levelProgress.level;
          final all = controller.rewards;
          final unlocked = all.where((r) => r.isUnlocked(level)).toList();
          final locked = all.where((r) => !r.isUnlocked(level)).toList();
          final shown = switch (_filter) {
            _RewardFilter.alle => all,
            _RewardFilter.freigeschaltet => unlocked,
            _RewardFilter.gesperrt => locked,
          };

          final labels = {
            _RewardFilter.alle: '${AppText.filterAll} (${all.length})',
            _RewardFilter.freigeschaltet:
                '${AppText.filterUnlocked} (${unlocked.length})',
            _RewardFilter.gesperrt:
                '${AppText.filterLocked} (${locked.length})',
          };

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppText.rewards,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 26)),
                            const SizedBox(height: 2),
                            const Text(AppText.rewardsSubline,
                                style: TextStyle(color: AppTheme.textMid)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            showRewardEditorSheet(context, controller),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(AppText.ownReward),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in labels.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _filter == entry.key,
                          onSelected: (_) =>
                              setState(() => _filter = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth > 640 ? 3 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        for (final reward in shown)
                          RewardCard(
                            controller: controller,
                            reward: reward,
                            onEdit: () => showRewardEditorSheet(
                                context, controller,
                                existing: reward),
                          ),
                        if (_filter == _RewardFilter.alle)
                          _AddRewardTile(
                            onTap: () =>
                                showRewardEditorSheet(context, controller),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('„${AppText.rewardsAreProgress}"',
                        style: AppTheme.quote),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddRewardTile extends StatelessWidget {
  const _AddRewardTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: _OutlineBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppTheme.textMid),
            const SizedBox(height: 8),
            Text(AppText.createOwnReward,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMid, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _OutlineBox extends StatelessWidget {
  const _OutlineBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardInset.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.border,
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Center(child: child),
    );
  }
}
