import 'package:flutter/foundation.dart';

/// The kinds of change a [Proposal] can carry. Deliberately small and
/// declarative so a proposal can be rendered as a human-readable diff and
/// replayed by [PlanService.apply].
enum PlanOperationKind {
  addOneOff,
  editOccurrence,
  moveOccurrence,
  removeOccurrence,
  skipOccurrence,
  createRecurring,
  placeQuotaOccurrence,
}

@immutable
class PlanOperation {
  const PlanOperation({
    required this.kind,
    this.occurrenceId,
    this.definitionId,
    this.targetDateKey,
    this.payload = const {},
    this.humanSummary = '',
  });

  final PlanOperationKind kind;
  final String? occurrenceId;
  final String? definitionId;
  final String? targetDateKey;

  /// Free-form fields for the operation (title, xp, categoryId, recurrence …).
  final Map<String, Object?> payload;

  /// One-line German description shown in the review sheet.
  final String humanSummary;

  Map<String, Object?> toMap() => {
        'kind': kind.name,
        'occurrenceId': occurrenceId,
        'definitionId': definitionId,
        'targetDateKey': targetDateKey,
        'payload': payload,
        'humanSummary': humanSummary,
      };

  factory PlanOperation.fromMap(Map<String, Object?> map) {
    return PlanOperation(
      kind: PlanOperationKind.values.firstWhere(
        (value) => value.name == map['kind'],
      ),
      occurrenceId: map['occurrenceId'] as String?,
      definitionId: map['definitionId'] as String?,
      targetDateKey: map['targetDateKey'] as String?,
      payload: (map['payload'] as Map? ?? const {}).cast<String, Object?>(),
      humanSummary: map['humanSummary'] as String? ?? '',
    );
  }
}

enum ProposalStatus { pending, approved, rejected }

/// A batch of proposed changes awaiting the user's approval.
///
/// **Only non-user actors create proposals.** The user's own edits apply
/// immediately. A future [AssistantGateway] can build proposals but has no
/// way to persist them without the user pressing "Übernehmen".
@immutable
class Proposal {
  const Proposal({
    required this.id,
    required this.source,
    required this.rationale,
    required this.operations,
    required this.createdAt,
    this.status = ProposalStatus.pending,
  });

  final String id;

  /// e.g. `ai:claude`, `ai:openai`, `bulk`.
  final String source;

  final String rationale;
  final List<PlanOperation> operations;
  final DateTime createdAt;
  final ProposalStatus status;

  Proposal copyWith({ProposalStatus? status}) => Proposal(
        id: id,
        source: source,
        rationale: rationale,
        operations: operations,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'source': source,
        'rationale': rationale,
        'operations': operations.map((op) => op.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory Proposal.fromMap(Map<String, Object?> map) {
    return Proposal(
      id: map['id']! as String,
      source: map['source'] as String? ?? 'unknown',
      rationale: map['rationale'] as String? ?? '',
      operations: [
        for (final op in (map['operations'] as List? ?? const []))
          PlanOperation.fromMap((op as Map).cast<String, Object?>()),
      ],
      createdAt: DateTime.parse(map['createdAt']! as String),
      status: ProposalStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => ProposalStatus.pending,
      ),
    );
  }
}
