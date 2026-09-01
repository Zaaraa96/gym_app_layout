import 'dart:async';

import 'models/workout_plan.dart';
import 'new_id.dart';
import 'plan_repository.dart';

/// In-memory [PlanRepository] for Flutter web. Isar 3.1 cannot open on web.
class MemoryPlanRepository implements PlanRepository {
  final _byId = <int, WorkoutPlan>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Future<int> count() async => _byId.length;

  @override
  Future<List<WorkoutPlan>> all() async {
    final items = _byId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<WorkoutPlan?> byId(int id) async => _byId[id];

  @override
  Future<WorkoutPlan?> byUuid(String uuid) async {
    for (final plan in _byId.values) {
      if (plan.uuid == uuid) return plan;
    }
    return null;
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
  Future<List<WorkoutPlan>> unsynced() async =>
      _byId.values.where((plan) => plan.dirty).toList();

  @override
  Future<bool> delete(int id) async {
    final removed = _byId.remove(id) != null;
    if (removed) _changes.add(null);
    return removed;
  }

  @override
  Stream<void> watch({bool fireImmediately = false}) async* {
    if (fireImmediately) yield null;
    yield* _changes.stream;
  }

  Future<int> _put(WorkoutPlan plan) async {
    if (plan.uuid.isEmpty) plan.uuid = newUuid();
    if (plan.id == unassignedLocalId) {
      plan.id = ++_nextId;
    }
    _byId[plan.id] = plan;
    _changes.add(null);
    return plan.id;
  }
}
