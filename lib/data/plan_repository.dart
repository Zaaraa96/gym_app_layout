import 'models/workout_plan.dart';

/// Reads and writes [WorkoutPlan]s. UI binds to this type, not a remote store.
abstract class PlanRepository {
  Future<int> count();

  /// Most recently edited first.
  Future<List<WorkoutPlan>> all();

  Future<WorkoutPlan?> byId(int id);

  Future<WorkoutPlan?> byUuid(String uuid);

  /// Local edit: bumps [WorkoutPlan.updatedAt] and marks [WorkoutPlan.dirty].
  Future<int> save(WorkoutPlan plan);

  /// Sync write: keeps timestamps and clears [WorkoutPlan.dirty].
  Future<int> putSynced(WorkoutPlan plan);

  Future<List<WorkoutPlan>> unsynced();

  Future<bool> delete(int id);

  /// Fires on any plan insert, update, or delete.
  Stream<void> watch({bool fireImmediately = false});
}
