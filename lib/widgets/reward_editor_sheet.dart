import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_text.dart';
import '../models/reward.dart';
import '../state/motivation_controller.dart';

Future<void> showRewardEditorSheet(
  BuildContext context,
  MotivationController controller, {
  Reward? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _RewardEditorSheet(controller: controller, existing: existing),
  );
}

class _RewardEditorSheet extends StatefulWidget {
  const _RewardEditorSheet({required this.controller, this.existing});

  final MotivationController controller;
  final Reward? existing;

  @override
  State<_RewardEditorSheet> createState() => _RewardEditorSheetState();
}

class _RewardEditorSheetState extends State<_RewardEditorSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _level = TextEditingController(
      text: '${widget.existing?.requiredLevel ?? 3}');
  late String _iconKey = widget.existing?.iconKey ?? 'game';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? AppText.newReward : AppText.edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: AppText.title),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _level,
              decoration:
                  const InputDecoration(labelText: AppText.requiredLevel),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in rewardIcons.entries)
                  ChoiceChip(
                    label: Icon(entry.value, size: 18),
                    selected: _iconKey == entry.key,
                    onSelected: (_) => setState(() => _iconKey = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton(
                    onPressed: () {
                      widget.controller.deleteReward(widget.existing!.id);
                      Navigator.pop(context);
                    },
                    child: const Text(AppText.delete),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _title.text.trim().isEmpty
                      ? null
                      : () {
                          final level =
                              int.tryParse(_level.text.trim()) ?? 1;
                          if (widget.existing == null) {
                            widget.controller.addReward(
                              title: _title.text,
                              description: _description.text,
                              iconKey: _iconKey,
                              requiredLevel: level,
                            );
                          } else {
                            widget.controller.updateReward(
                              widget.existing!.id,
                              title: _title.text,
                              description: _description.text,
                              iconKey: _iconKey,
                              requiredLevel: level,
                            );
                          }
                          Navigator.pop(context);
                        },
                  child: const Text(AppText.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
