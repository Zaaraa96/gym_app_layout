import 'dart:convert';
import 'dart:io';

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

  // #region agent log
  void _dbg(String hyp, String loc, String msg, Map<String, Object?> data) {
    try {
      File('/opt/cursor/logs/debug.log').writeAsStringSync(
        '${jsonEncode({
          'hypothesisId': hyp,
          'location': loc,
          'message': msg,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        })}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
  // #endregion

  @override
  Future<List<PlanDaySkip>> all() async {
    final rows = await _isar.planDaySkips.where().findAll();
    final out = [for (final row in rows) skipFromIsar(row)];
    // #region agent log
    _dbg('A', 'isar_skip_repository.dart:all', 'skips.all', {
      'count': out.length,
      'planIds': [for (final s in out) s.planId],
      'dayIds': [for (final s in out) s.dayId],
      'ids': [for (final s in out) s.id],
    });
    // #endregion
    return out;
  }

  @override
  Future<List<PlanDaySkip>> forPlan(String planId) async {
    final rows =
        await _isar.planDaySkips.filter().planIdEqualTo(planId).findAll();
    final out = [for (final row in rows) skipFromIsar(row)];
    // #region agent log
    final allRows = await _isar.planDaySkips.where().findAll();
    _dbg('A', 'isar_skip_repository.dart:forPlan', 'skips.forPlan', {
      'queryPlanId': planId,
      'count': out.length,
      'dayIds': [for (final s in out) s.dayId],
      'allCount': allRows.length,
      'allPlanIds': [for (final r in allRows) r.planId],
      'allDayIds': [for (final r in allRows) r.dayId],
    });
    // #endregion
    return out;
  }

  @override
  Future<int> save(PlanDaySkip skip) {
    if (skip.uuid.isEmpty) skip.uuid = newUuid();
    skip.date = utcCalendarDay(skip.date);
    final row = skipToIsar(skip);
    // #region agent log
    _dbg('B', 'isar_skip_repository.dart:save:before', 'skip save before put', {
      'planId': skip.planId,
      'dayId': skip.dayId,
      'uuid': skip.uuid,
      'domainId': skip.id,
      'rowId': row.id,
      'date': skip.date.toIso8601String(),
    });
    // #endregion
    return _isar.writeTxn(() async {
      final id = await _isar.planDaySkips.put(row);
      skip.id = id;
      // #region agent log
      _dbg('B', 'isar_skip_repository.dart:save:after', 'skip save after put', {
        'assignedId': id,
        'planId': skip.planId,
        'dayId': skip.dayId,
        'collectionCount': await _isar.planDaySkips.count(),
      });
      // #endregion
      return id;
    });
  }

  @override
  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.planDaySkips.delete(id));

  @override
  Future<void> deleteForPlan(String planId) {
    return _isar.writeTxn(() async {
      await _isar.planDaySkips.filter().planIdEqualTo(planId).deleteAll();
    });
  }

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
