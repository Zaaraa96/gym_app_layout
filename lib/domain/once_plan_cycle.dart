import 'dart:convert';
import 'dart:io';

import 'models/models.dart';
import 'plan_repository.dart';
import 'session_repository.dart';
import 'skip_repository.dart';

/// Whether a completed session counts toward the current Run-once cycle.
bool sessionCountsForOnceCycle(WorkoutPlan plan, WorkoutSession session) {
  final start = plan.onceCycleStartedAt;
  if (start == null) return true;
  return !session.startedAt.toUtc().isBefore(start.toUtc());
}

/// Whether a skip counts toward the current Run-once cycle.
bool skipCountsForOnceCycle(WorkoutPlan plan, PlanDaySkip skip) {
  final start = plan.onceCycleStartedAt;
  if (start == null) return true;
  return !skip.date.isBefore(utcCalendarDay(start));
}

/// True when every startable workout day is completed or skipped in this cycle.
bool oncePlanIsFinished({
  required WorkoutPlan plan,
  required List<WorkoutSession> completedNewestFirst,
  required List<PlanDaySkip> skips,
}) {
  if (plan.scheduleMode != ScheduleMode.once) return false;
  final startable = [
    for (final day in plan.days)
      if (day.blocks.isNotEmpty) day,
  ];
  if (startable.isEmpty) return false;

  for (final day in startable) {
    final done = completedNewestFirst.any(
      (s) =>
          s.planId == plan.uuid &&
          s.planDayId == day.dayId &&
          sessionCountsForOnceCycle(plan, s),
    );
    final skipped = skips.any(
      (s) =>
          s.planId == plan.uuid &&
          s.dayId == day.dayId &&
          skipCountsForOnceCycle(plan, s),
    );
    if (!done && !skipped) return false;
  }
  return true;
}

/// Parks a finished Run-once plan: [WorkoutPlan.onSchedule] = false.
///
/// Returns true when the plan was updated.
Future<bool> parkOncePlanIfFinished({
  required WorkoutPlan plan,
  required PlanRepository plans,
  required List<WorkoutSession> completedNewestFirst,
  required List<PlanDaySkip> skips,
}) async {
  if (plan.scheduleMode != ScheduleMode.once) return false;
  if (!plan.onSchedule) {
    // Already parked; still finished.
    return oncePlanIsFinished(
      plan: plan,
      completedNewestFirst: completedNewestFirst,
      skips: skips,
    );
  }
  if (!oncePlanIsFinished(
    plan: plan,
    completedNewestFirst: completedNewestFirst,
    skips: skips,
  )) {
    return false;
  }
  plan.onSchedule = false;
  await plans.save(plan);
  return true;
}

/// Starts a new Run-once cycle and puts the plan back on Today.
///
/// Clears once skips for this plan. Month session history is kept; only the
/// new cycle counts for Today progress. When the cycle finishes again,
/// [parkOncePlanIfFinished] turns On schedule off.
Future<void> restartOncePlan({
  required WorkoutPlan plan,
  required PlanRepository plans,
  required SkipRepository skips,
  DateTime? now,
}) async {
  if (plan.scheduleMode != ScheduleMode.once) {
    throw StateError('Only Run once plans can be restarted this way.');
  }
  final clock = (now ?? DateTime.now()).toUtc();
  plan.onceCycleStartedAt = clock;
  plan.onSchedule = true;
  await skips.deleteForPlan(plan.uuid);
  await plans.save(plan);
}

/// Convenience after a session finish or skip for [planId].
Future<void> parkOncePlanByIdIfFinished({
  required String planId,
  required PlanRepository plans,
  required SessionRepository sessions,
  required SkipRepository skips,
}) async {
  final plan = await plans.byUuid(planId);
  if (plan == null) return;
  if (plan.scheduleMode != ScheduleMode.once) return;
  final completed = await sessions.completedNewestFirst(planId: planId);
  final skipRows = await skips.forPlan(planId);
  final finished = oncePlanIsFinished(
    plan: plan,
    completedNewestFirst: completed,
    skips: skipRows,
  );
  // #region agent log
  try {
    File('/opt/cursor/logs/debug.log').writeAsStringSync(
      '${jsonEncode({
        'hypothesisId': 'E',
        'location': 'once_plan_cycle.dart:parkById',
        'message': 'parkOncePlanByIdIfFinished',
        'data': {
          'planId': planId,
          'onScheduleBefore': plan.onSchedule,
          'finished': finished,
          'skipCount': skipRows.length,
          'skipDayIds': [for (final s in skipRows) s.dayId],
          'dayIds': [for (final d in plan.days) d.dayId],
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      })}\n',
      mode: FileMode.append,
    );
  } catch (_) {}
  // #endregion
  await parkOncePlanIfFinished(
    plan: plan,
    plans: plans,
    completedNewestFirst: completed,
    skips: skipRows,
  );
}
