import 'package:isar/isar.dart';

import 'isar/mappers.dart';
import 'isar/workout_plan.dart' as isar_plan;
import '../domain/models/workout_plan.dart';
import '../domain/new_id.dart';
import '../domain/plan_repository.dart';

/// Isar-backed [PlanRepository]. The only plan writer the UI talks to.
class IsarPlanRepository implements PlanRepository {
  IsarPlanRepository(this._isar);

  final Isar _isar;

  @override
  Future<int> count() => _isar.workoutPlans.count();

  @override
  Future<List<WorkoutPlan>> all() async {
    final rows =
        await _isar.workoutPlans.where().sortByUpdatedAtDesc().findAll();
    return [for (final row in rows) planFromIsar(row)];
  }

  @override
  Future<WorkoutPlan?> byId(int id) async {
    final row = await _isar.workoutPlans.get(id);
    return row == null ? null : planFromIsar(row);
  }

  @override
  Future<WorkoutPlan?> byUuid(String uuid) async {
    final row = await _isar.workoutPlans.filter().uuidEqualTo(uuid).findFirst();
    return row == null ? null : planFromIsar(row);
  }

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
  Future<List<WorkoutPlan>> unsynced() async {
    final rows = await _isar.workoutPlans.filter().dirtyEqualTo(true).findAll();
    return [for (final row in rows) planFromIsar(row)];
  }

  @override
  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutPlans.delete(id));

  @override
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.workoutPlans.watchLazy(fireImmediately: fireImmediately);

  Future<int> _put(WorkoutPlan plan) {
    if (plan.uuid.isEmpty) plan.uuid = newUuid();
    final row = planToIsar(plan);
    return _isar.writeTxn(() async {
      final id = await _isar.workoutPlans.put(row);
      plan.id = id;
      return id;
    });
  }
}
