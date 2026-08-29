import 'package:isar/isar.dart';

import 'models/models.dart';
import 'new_id.dart';
import 'session_repository.dart';

/// Isar-backed [SessionRepository]. The only session writer the UI talks to.
class IsarSessionRepository implements SessionRepository {
  IsarSessionRepository(this._isar);

  final Isar _isar;

  @override
  Future<WorkoutSession?> byId(int id) => _isar.workoutSessions.get(id);

  @override
  Future<WorkoutSession?> byUuid(String uuid) =>
      _isar.workoutSessions.filter().uuidEqualTo(uuid).findFirst();

  @override
  Future<int> save(WorkoutSession session) {
    session.updatedAt = DateTime.now().toUtc();
    session.dirty = true;
    return _put(session);
  }

  @override
  Future<int> putSynced(WorkoutSession session) {
    session.dirty = false;
    return _put(session);
  }

  @override
  Future<List<WorkoutSession>> unsynced() =>
      _isar.workoutSessions.filter().dirtyEqualTo(true).findAll();

  @override
  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutSessions.delete(id));

  @override
  Future<WorkoutSession?> inProgress() => _isar.workoutSessions
      .filter()
      .statusEqualTo(SessionStatus.inProgress)
      .findFirst();

  @override
  Future<WorkoutSession?> lastCompleted({String? planId}) {
    final query =
        _isar.workoutSessions.filter().statusEqualTo(SessionStatus.completed);
    if (planId == null) {
      return query.sortByStartedAtDesc().findFirst();
    }
    return query.planIdEqualTo(planId).sortByStartedAtDesc().findFirst();
  }

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) {
    final query =
        _isar.workoutSessions.filter().statusEqualTo(SessionStatus.completed);
    if (planId == null) {
      return query.sortByStartedAtDesc().findAll();
    }
    return query.planIdEqualTo(planId).sortByStartedAtDesc().findAll();
  }

  @override
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

  @override
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

  @override
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.workoutSessions.watchLazy(fireImmediately: fireImmediately);

  Future<int> _put(WorkoutSession session) {
    if (session.uuid.isEmpty) session.uuid = newUuid();
    return _isar.writeTxn(() => _isar.workoutSessions.put(session));
  }
}
