import 'models/models.dart';
import 'new_id.dart';
import 'session_repository.dart';

/// Product rules for starting and abandoning sessions.
///
/// Both local and remote persistence stay free of "one in-progress session".
class SessionLifecycle {
  SessionLifecycle(this._sessions);

  final SessionRepository _sessions;

  /// Snapshot the day's blocks, then each included common section, into logs.
  ///
  /// Fails when another session is already [SessionStatus.inProgress].
  Future<WorkoutSession> start({
    required WorkoutPlan plan,
    required String planDayId,
    List<String> includedCommonSectionIds = const [],
    DateTime? startedAt,
  }) async {
    final existing = await _sessions.inProgress();
    if (existing != null) {
      throw StateError('A workout is already in progress');
    }

    PlanDay? day;
    for (final item in plan.days) {
      if (item.dayId == planDayId) {
        day = item;
        break;
      }
    }
    if (day == null) {
      throw ArgumentError.value(planDayId, 'planDayId', 'Day not on this plan');
    }

    final now = (startedAt ?? DateTime.now()).toUtc();
    final session = WorkoutSession.create(
      uuid: newUuid(),
      planId: plan.uuid,
      planDayId: day.dayId,
      planTitleSnapshot: plan.title,
      dayTitleSnapshot: day.title,
      startedAt: now,
      updatedAt: now,
      status: SessionStatus.inProgress,
      includedCommonSectionIds: includedCommonSectionIds,
      exerciseLogs: exerciseLogsForStart(
        day: day,
        commonSections: plan.commonSections,
        includedCommonSectionIds: includedCommonSectionIds,
      ),
    );
    session.id = await _sessions.save(session);
    return session;
  }

  Future<void> abandonInProgress({DateTime? endedAt}) async {
    final current = await _sessions.inProgress();
    if (current == null) return;
    current.status = SessionStatus.abandoned;
    current.endedAt = (endedAt ?? DateTime.now()).toUtc();
    await _sessions.save(current);
  }

  /// The live session, if any. Opening it is resume.
  Future<WorkoutSession?> resume() => _sessions.inProgress();
}

/// Day blocks first, then each enabled common section, in order.
List<ExerciseLog> exerciseLogsForStart({
  required PlanDay day,
  required List<CommonSection> commonSections,
  required List<String> includedCommonSectionIds,
}) {
  final logs = <ExerciseLog>[];
  for (final block in day.blocks) {
    logs.addAll(_logsForBlock(block, fromCommonSection: false));
  }
  for (final sectionId in includedCommonSectionIds) {
    CommonSection? section;
    for (final item in commonSections) {
      if (item.sectionId == sectionId) {
        section = item;
        break;
      }
    }
    if (section == null) continue;
    logs.addAll([
      for (final block in section.blocks)
        ..._logsForBlock(block, fromCommonSection: true),
    ]);
  }
  return logs;
}

List<ExerciseLog> _logsForBlock(
  ExerciseBlock block, {
  required bool fromCommonSection,
}) {
  return [
    for (final exercise in block.exercises)
      ExerciseLog.create(
        prescriptionId: exercise.prescriptionId,
        blockId: block.blockId,
        blockKind: block.kind,
        fromCommonSection: fromCommonSection,
        exerciseTitle: exercise.title,
        exerciseTitleKey: exerciseTitleKeyFor(exercise.title),
        prescribedSets: exercise.prescribedSets,
        prescribedReps: exercise.prescribedReps,
        prescribedDurationSeconds: exercise.prescribedDurationSeconds,
      ),
  ];
}
