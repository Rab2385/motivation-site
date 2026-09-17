import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../models/proposal.dart';
import '../state/motivation_controller.dart';

/// Renders a [Proposal] as a human-readable diff with approve / reject.
///
/// This is the UI half of the AI seam. Only non-user actors create proposals;
/// nothing here is persisted until the user taps "Apply".
Future<void> showProposalReviewSheet(
  BuildContext context,
  MotivationController controller,
  Proposal proposal,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProposalReviewSheet(
      controller: controller,
      proposal: proposal,
    ),
  );
}

class _ProposalReviewSheet extends StatelessWidget {
  const _ProposalReviewSheet({
    required this.controller,
    required this.proposal,
  });

  final MotivationController controller;
  final Proposal proposal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.assistantProposal, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(AppText.proposalIntro, style: theme.textTheme.bodySmall),
          if (proposal.rationale.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(proposal.rationale, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final op in proposal.operations)
                  ListTile(
                    dense: true,
                    leading: Icon(_iconFor(op.kind), size: 18),
                    title: Text(op.humanSummary.isEmpty
                        ? op.kind.name
                        : op.humanSummary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.rejectProposal(proposal.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text(AppText.discard),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    controller.approveProposal(proposal.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text(AppText.apply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PlanOperationKind kind) {
    switch (kind) {
      case PlanOperationKind.addOneOff:
      case PlanOperationKind.createRecurring:
      case PlanOperationKind.placeQuotaOccurrence:
        return Icons.add_circle_outline;
      case PlanOperationKind.editOccurrence:
        return Icons.edit_outlined;
      case PlanOperationKind.moveOccurrence:
        return Icons.swap_horiz;
      case PlanOperationKind.removeOccurrence:
        return Icons.remove_circle_outline;
      case PlanOperationKind.skipOccurrence:
        return Icons.block_outlined;
    }
  }
}
