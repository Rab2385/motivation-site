import '../models/proposal.dart';
import '../models/task_category.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../domain/statistics.dart';

/// Read-only context handed to an assistant. It deliberately contains plain
/// data only – no database, no [PlanService] – so an assistant can reason but
/// cannot write.
class PlanContext {
  const PlanContext({
    required this.today,
    required this.categories,
    required this.definitions,
    required this.occurrences,
    required this.dayTargetXp,
    required this.stats,
  });

  final DateTime today;
  final List<TaskCategory> categories;
  final List<TaskDefinition> definitions;
  final List<TaskOccurrence> occurrences;
  final List<int> dayTargetXp;
  final StatsSnapshot stats;
}

class DraftTask {
  const DraftTask({
    required this.title,
    required this.categoryId,
    this.note = '',
  });

  final String title;
  final String categoryId;
  final String note;
}

class XpSuggestion {
  const XpSuggestion({required this.title, required this.xp, this.rationale = ''});

  final String title;
  final int xp;
  final String rationale;
}

/// The seam a future AI assistant plugs into.
///
/// **No implementation ships in V1.** When one is added it must:
///
/// * only ever return [Proposal]s – it cannot mutate anything directly;
/// * never see an API key in the Flutter client (a real gateway calls a thin
///   backend proxy that holds the key);
/// * be entirely optional – the app is fully functional without it and
///   offline.
///
/// Every [Proposal] it produces is shown to the user as a diff and is
/// discarded unless the user approves it.
abstract class AssistantGateway {
  /// Turn a natural-language description of the week into a proposed plan.
  Future<Proposal> planWeek(PlanContext context, String naturalLanguage);

  /// Suggest realistic XP values for a set of draft tasks.
  Future<List<XpSuggestion>> suggestXp(
    PlanContext context,
    List<DraftTask> drafts,
  );

  /// A short written reflection on the past week.
  Future<String> weeklyReflection(PlanContext context);
}
