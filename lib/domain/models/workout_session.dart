import '../new_id.dart';
import 'enums.dart';
import 'workout_plan.dart';

/// What happened on a date. Snapshots the prescription at start so plan edits
/// do not rewrite history.
class WorkoutSession {
  /// Local row key assigned by a repository. Not the identity sent to a remote API.
  int id = unassignedLocalId;

  /// Stable identity for sync.
  late String uuid;

  /// [WorkoutPlan.uuid]. Plan may later be deleted; this snapshot still stands.
  late String planId;

  late String planDayId;
  late String planTitleSnapshot;
  late String dayTitleSnapshot;

  /// Common sections chosen when the session started.
  List<String> includedCommonSectionIds = [];

  late DateTime startedAt;

  DateTime? endedAt;

  /// Used for last-write-wins sync.
  late DateTime updatedAt;

  /// True when a local write has not been acknowledged by sync.
  bool dirty = true;

  late SessionStatus status;

  /// Day blocks, then included common blocks, in order.
  List<ExerciseLog> exerciseLogs = [];

  WorkoutSession();

  WorkoutSession.create({
    String? uuid,
    this.dirty = true,
    required this.planId,
    required this.planDayId,
    required this.planTitleSnapshot,
    required this.dayTitleSnapshot,
    required this.startedAt,
    required this.status,
    DateTime? updatedAt,
    this.endedAt,
    List<String>? includedCommonSectionIds,
    List<ExerciseLog>? exerciseLogs,
  })  : uuid = uuid ?? newUuid(),
        updatedAt = updatedAt ?? startedAt,
        includedCommonSectionIds = includedCommonSectionIds ?? [],
        exerciseLogs = exerciseLogs ?? [];
}

class ExerciseLog {
  /// From the template prescription.
  late String prescriptionId;
  late String blockId;

  late BlockKind blockKind;

  late bool fromCommonSection;
  late String exerciseTitle;

  /// Snapshot of the normalized name used to group progress.
  late String exerciseTitleKey;

  late int prescribedSets;
  int? prescribedReps;
  int? prescribedDurationSeconds;

  List<SetLog> sets = [];

  /// 1–5. Required to mark this exercise complete.
  int? difficulty;

  /// Set when difficulty is saved.
  DateTime? completedAt;

  ExerciseLog();

  ExerciseLog.create({
    required this.prescriptionId,
    required this.blockId,
    required this.blockKind,
    required this.fromCommonSection,
    required this.exerciseTitle,
    required this.exerciseTitleKey,
    required this.prescribedSets,
    this.prescribedReps,
    this.prescribedDurationSeconds,
    this.difficulty,
    this.completedAt,
    List<SetLog>? sets,
  }) : sets = sets ?? [];

  /// An exercise is complete when [difficulty] is set. Sets may be logged first.
  bool get isComplete => difficulty != null;
}

class SetLog {
  /// 1-based.
  late int setIndex;

  int? reps;

  /// Null = bodyweight or not entered.
  double? weightKg;

  int? durationSeconds;

  late DateTime completedAt;

  SetLog();

  SetLog.create({
    required this.setIndex,
    required this.completedAt,
    this.reps,
    this.weightKg,
    this.durationSeconds,
  });
}
