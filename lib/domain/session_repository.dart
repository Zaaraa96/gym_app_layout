import 'models/models.dart';

/// Reads and writes [WorkoutSession]s. UI binds to this type, not a remote store.
abstract class SessionRepository {
  Future<WorkoutSession?> byId(int id);

  Future<WorkoutSession?> byUuid(String uuid);

  /// Local edit: bumps [WorkoutSession.updatedAt] and marks [WorkoutSession.dirty].
  Future<int> save(WorkoutSession session);

  /// Sync write: keeps timestamps and clears [WorkoutSession.dirty].
  Future<int> putSynced(WorkoutSession session);

  Future<List<WorkoutSession>> unsynced();

  Future<bool> delete(int id);

  /// At most one in-progress session is expected. Returns the first if several.
  Future<WorkoutSession?> inProgress();

  /// Newest completed session, optionally for one plan ([WorkoutPlan.uuid]).
  Future<WorkoutSession?> lastCompleted({String? planId});

  /// Completed sessions, newest [WorkoutSession.startedAt] first.
  Future<List<WorkoutSession>> completedNewestFirst({String? planId});

  /// Non-abandoned sessions whose [WorkoutSession.startedAt] falls in [month].
  Future<List<WorkoutSession>> forMonth(DateTime month);

  /// Non-abandoned sessions on that calendar day, oldest [startedAt] first.
  Future<List<WorkoutSession>> forCalendarDay(DateTime day);

  /// Fires on any session insert, update, or delete.
  Stream<void> watch({bool fireImmediately = false});
}
