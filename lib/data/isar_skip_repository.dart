import 'package:isar/isar.dart';

import 'isar/plan_day_skip.dart' as isar_skip;
import '../domain/models/schedule.dart';
import '../domain/models/workout_plan.dart';
import '../domain/new_id.dart';
import '../domain/skip_repository.dart';

/// Isar-backed [SkipRepository].
class IsarSkipRepository implements SkipRepository {
  IsarSkipRepository(this._isar);

  final Isar _isar;

  @override
  Future<List<PlanDaySkip>> all() async {
    final rows = await _isar.planDaySkips.where().findAll();
    return [for (final row in rows) skipFromIsar(row)];
  }

  @override
  Future<List<PlanDaySkip>> forPlan(String planId) async {
    final rows =
        await _isar.planDaySkips.filter().planIdEqualTo(planId).findAll();
    return [for (final row in rows) skipFromIsar(row)];
  }

  @override
  Future<int> save(PlanDaySkip skip) {
    if (skip.uuid.isEmpty) skip.uuid = newUuid();
    skip.date = utcCalendarDay(skip.date);
    final row = skipToIsar(skip);
    return _isar.writeTxn(() async {
      final id = await _isar.planDaySkips.put(row);
      skip.id = id;
      return id;
    });
  }

  @override
  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.planDaySkips.delete(id));

  @override
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.planDaySkips.watchLazy(fireImmediately: fireImmediately);
}

isar_skip.PlanDaySkip skipToIsar(PlanDaySkip skip) {
  return isar_skip.PlanDaySkip()
    ..id = skip.id == unassignedLocalId ? Isar.autoIncrement : skip.id
    ..uuid = skip.uuid
    ..planId = skip.planId
    ..dayId = skip.dayId
    ..date = utcCalendarDay(skip.date);
}

PlanDaySkip skipFromIsar(isar_skip.PlanDaySkip row) {
  return PlanDaySkip.create(
    uuid: row.uuid,
    planId: row.planId,
    dayId: row.dayId,
    date: row.date,
  )..id = row.id;
}
