import 'package:isar/isar.dart';

import 'models/models.dart';

/// Reads and writes [WorkoutSession]s. The only place that touches the session
/// collection.
class SessionRepository {
  SessionRepository(this._isar);

  final Isar _isar;

  Future<WorkoutSession?> byId(int id) => _isar.workoutSessions.get(id);

  Future<int> save(WorkoutSession session) =>
      _isar.writeTxn(() => _isar.workoutSessions.put(session));

  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutSessions.delete(id));

  /// At most one in-progress session is expected. Returns the first if several.
  Future<WorkoutSession?> inProgress() => _isar.workoutSessions
      .filter()
      .statusEqualTo(SessionStatus.inProgress)
      .findFirst();

  /// Newest completed session, optionally for one plan.
  Future<WorkoutSession?> lastCompleted({int? planId}) {
    final query = _isar.workoutSessions
        .filter()
        .statusEqualTo(SessionStatus.completed);
    if (planId == null) {
      return query.sortByStartedAtDesc().findFirst();
    }
    return query.planIdEqualTo(planId).sortByStartedAtDesc().findFirst();
  }

  /// Completed sessions, newest [WorkoutSession.startedAt] first.
  Future<List<WorkoutSession>> completedNewestFirst({int? planId}) {
    final query = _isar.workoutSessions
        .filter()
        .statusEqualTo(SessionStatus.completed);
    if (planId == null) {
      return query.sortByStartedAtDesc().findAll();
    }
    return query.planIdEqualTo(planId).sortByStartedAtDesc().findAll();
  }

  /// Non-abandoned sessions whose [WorkoutSession.startedAt] falls in [month].
  Future<List<WorkoutSession>> forMonth(DateTime month) {
    final start = DateTime.utc(month.year, month.month);
    final end = DateTime.utc(month.year, month.month + 1);
    return _isar.workoutSessions
        .where()
        .startedAtBetween(start, end, includeLower: true, includeUpper: false)
        .filter()
        .group(
          (q) => q
              .statusEqualTo(SessionStatus.inProgress)
              .or()
              .statusEqualTo(SessionStatus.completed),
        )
        .sortByStartedAt()
        .findAll();
  }

  /// Non-abandoned sessions on that calendar day, oldest [startedAt] first.
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _isar.workoutSessions
        .where()
        .startedAtBetween(start, end, includeLower: true, includeUpper: false)
        .filter()
        .group(
          (q) => q
              .statusEqualTo(SessionStatus.inProgress)
              .or()
              .statusEqualTo(SessionStatus.completed),
        )
        .sortByStartedAt()
        .findAll();
  }

  /// Snapshot the day's blocks, then each included common section, into logs.
  Future<WorkoutSession> start({
    required WorkoutPlan plan,
    required String planDayId,
    List<String> includedCommonSectionIds = const [],
    DateTime? startedAt,
  }) async {
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
      planId: plan.id,
      planDayId: day.dayId,
      planTitleSnapshot: plan.title,
      dayTitleSnapshot: day.title,
      startedAt: now,
      status: SessionStatus.inProgress,
      includedCommonSectionIds: includedCommonSectionIds,
      exerciseLogs: exerciseLogsForStart(
        day: day,
        commonSections: plan.commonSections,
        includedCommonSectionIds: includedCommonSectionIds,
      ),
    );
    session.id = await save(session);
    return session;
  }

  Future<void> abandonInProgress({DateTime? endedAt}) async {
    final current = await inProgress();
    if (current == null) return;
    current.status = SessionStatus.abandoned;
    current.endedAt = (endedAt ?? DateTime.now()).toUtc();
    await save(current);
  }

  /// Fires on any session insert, update, or delete.
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.workoutSessions.watchLazy(fireImmediately: fireImmediately);
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
