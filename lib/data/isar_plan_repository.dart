import 'package:isar/isar.dart';

import 'models/workout_plan.dart';
import 'new_id.dart';
import 'plan_repository.dart';

/// Isar-backed [PlanRepository]. The only plan writer the UI talks to.
class IsarPlanRepository implements PlanRepository {
  IsarPlanRepository(this._isar);

  final Isar _isar;

  @override
  Future<int> count() => _isar.workoutPlans.count();

  @override
  Future<List<WorkoutPlan>> all() =>
      _isar.workoutPlans.where().sortByUpdatedAtDesc().findAll();

  @override
  Future<WorkoutPlan?> byId(int id) => _isar.workoutPlans.get(id);

  @override
  Future<WorkoutPlan?> byUuid(String uuid) =>
      _isar.workoutPlans.filter().uuidEqualTo(uuid).findFirst();

  @override
  Future<int> save(WorkoutPlan plan) {
    plan.updatedAt = DateTime.now().toUtc();
    plan.dirty = true;
    return _put(plan);
  }

  @override
  Future<int> putSynced(WorkoutPlan plan) {
    plan.dirty = false;
    return _put(plan);
  }

  @override
  Future<List<WorkoutPlan>> unsynced() =>
      _isar.workoutPlans.filter().dirtyEqualTo(true).findAll();

  @override
  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutPlans.delete(id));

  @override
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.workoutPlans.watchLazy(fireImmediately: fireImmediately);

  Future<int> _put(WorkoutPlan plan) {
    if (plan.uuid.isEmpty) plan.uuid = newUuid();
    return _isar.writeTxn(() => _isar.workoutPlans.put(plan));
  }
}
