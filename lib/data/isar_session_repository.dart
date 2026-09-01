import 'package:isar/isar.dart';

import 'isar/mappers.dart';
import 'isar/workout_session.dart' as isar_session;
import 'models/models.dart';
import 'new_id.dart';
import 'session_repository.dart';

/// Isar-backed [SessionRepository]. The only session writer the UI talks to.
class IsarSessionRepository implements SessionRepository {
  IsarSessionRepository(this._isar);

  final Isar _isar;

  @override
  Future<WorkoutSession?> byId(int id) async {
    final row = await _isar.workoutSessions.get(id);
    return row == null ? null : sessionFromIsar(row);
  }

  @override
  Future<WorkoutSession?> byUuid(String uuid) async {
    final row =
        await _isar.workoutSessions.filter().uuidEqualTo(uuid).findFirst();
    return row == null ? null : sessionFromIsar(row);
  }

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
  Future<List<WorkoutSession>> unsynced() async {
    final rows =
        await _isar.workoutSessions.filter().dirtyEqualTo(true).findAll();
    return [for (final row in rows) sessionFromIsar(row)];
  }

  @override
  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutSessions.delete(id));

  @override
  Future<WorkoutSession?> inProgress() async {
    final row = await _isar.workoutSessions
        .filter()
        .statusEqualTo(SessionStatus.inProgress)
        .findFirst();
    return row == null ? null : sessionFromIsar(row);
  }

  @override
  Future<WorkoutSession?> lastCompleted({String? planId}) async {
    final query =
        _isar.workoutSessions.filter().statusEqualTo(SessionStatus.completed);
    final row = planId == null
        ? await query.sortByStartedAtDesc().findFirst()
        : await query.planIdEqualTo(planId).sortByStartedAtDesc().findFirst();
    return row == null ? null : sessionFromIsar(row);
  }

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) async {
    final query =
        _isar.workoutSessions.filter().statusEqualTo(SessionStatus.completed);
    final rows = planId == null
        ? await query.sortByStartedAtDesc().findAll()
        : await query.planIdEqualTo(planId).sortByStartedAtDesc().findAll();
    return [for (final row in rows) sessionFromIsar(row)];
  }

  @override
  Future<List<WorkoutSession>> forMonth(DateTime month) async {
    final start = DateTime.utc(month.year, month.month);
    final end = DateTime.utc(month.year, month.month + 1);
    final rows = await _isar.workoutSessions
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
    return [for (final row in rows) sessionFromIsar(row)];
  }

  @override
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _isar.workoutSessions
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
    return [for (final row in rows) sessionFromIsar(row)];
  }

  @override
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.workoutSessions.watchLazy(fireImmediately: fireImmediately);

  Future<int> _put(WorkoutSession session) {
    if (session.uuid.isEmpty) session.uuid = newUuid();
    final row = sessionToIsar(session);
    return _isar.writeTxn(() async {
      final id = await _isar.workoutSessions.put(row);
      session.id = id;
      return id;
    });
  }
}
