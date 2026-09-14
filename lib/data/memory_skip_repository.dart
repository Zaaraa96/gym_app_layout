import 'dart:async';

import '../domain/models/schedule.dart';
import '../domain/new_id.dart';
import '../domain/skip_repository.dart';
import '../domain/models/workout_plan.dart';

/// In-memory [SkipRepository] for tests and web.
class MemorySkipRepository implements SkipRepository {
  final _byId = <int, PlanDaySkip>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Future<List<PlanDaySkip>> all() async => _byId.values.toList();

  @override
  Future<List<PlanDaySkip>> forPlan(String planId) async =>
      _byId.values.where((s) => s.planId == planId).toList();

  @override
  Future<int> save(PlanDaySkip skip) async {
    if (skip.uuid.isEmpty) skip.uuid = newUuid();
    skip.date = utcCalendarDay(skip.date);
    if (skip.id == unassignedLocalId) {
      skip.id = ++_nextId;
    }
    _byId[skip.id] = skip;
    _changes.add(null);
    return skip.id;
  }

  @override
  Future<bool> delete(int id) async {
    final removed = _byId.remove(id) != null;
    if (removed) _changes.add(null);
    return removed;
  }

  @override
  Future<void> deleteForPlan(String planId) async {
    final ids = [
      for (final entry in _byId.entries)
        if (entry.value.planId == planId) entry.key,
    ];
    if (ids.isEmpty) return;
    for (final id in ids) {
      _byId.remove(id);
    }
    _changes.add(null);
  }

  @override
  Stream<void> watch({bool fireImmediately = false}) async* {
    if (fireImmediately) yield null;
    yield* _changes.stream;
  }
}
