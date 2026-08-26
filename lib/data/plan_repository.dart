import 'package:isar/isar.dart';

import 'models/workout_plan.dart';

/// Reads and writes [WorkoutPlan]s. The only place that touches the plan
/// collection.
class PlanRepository {
  PlanRepository(this._isar);

  final Isar _isar;

  Future<int> count() => _isar.workoutPlans.count();

  /// Most recently edited first.
  Future<List<WorkoutPlan>> all() =>
      _isar.workoutPlans.where().sortByUpdatedAtDesc().findAll();

  Future<WorkoutPlan?> byId(int id) => _isar.workoutPlans.get(id);

  Future<int> save(WorkoutPlan plan) {
    plan.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.workoutPlans.put(plan));
  }

  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutPlans.delete(id));

  /// Fires on any plan insert, update, or delete.
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.workoutPlans.watchLazy(fireImmediately: fireImmediately);
}
