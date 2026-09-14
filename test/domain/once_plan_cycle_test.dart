import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/memory_skip_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/once_plan_cycle.dart';
import 'package:gym_app/domain/today_suggestion.dart';

void main() {
  test('finished once plan parks off schedule', () async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final skips = MemorySkipRepository();
    final plan = _oncePlan();
    await plans.save(plan);
    await sessions.save(_completed(plan.uuid, 'day-1'));
    await sessions.save(_completed(plan.uuid, 'day-2'));

    final parked = await parkOncePlanIfFinished(
      plan: plan,
      plans: plans,
      completedNewestFirst: await sessions.completedNewestFirst(),
      skips: await skips.all(),
    );
    expect(parked, isTrue);
    expect(plan.onSchedule, isFalse);
    expect(suggestTodayItems(plans: [plan]), isEmpty);
  });

  test('Run again starts a new cycle on schedule without old progress', () async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final skips = MemorySkipRepository();
    final plan = _oncePlan()..onSchedule = false;
    await plans.save(plan);
    await sessions.save(
      _completed(plan.uuid, 'day-1', at: DateTime.utc(2026, 1, 1)),
    );
    await sessions.save(
      _completed(plan.uuid, 'day-2', at: DateTime.utc(2026, 1, 2)),
    );
    await skips.save(
      PlanDaySkip.create(
        planId: plan.uuid,
        dayId: 'day-1',
        date: DateTime.utc(2026, 1, 1),
      ),
    );

    await restartOncePlan(
      plan: plan,
      plans: plans,
      skips: skips,
      now: DateTime.utc(2026, 2, 1, 12),
    );

    expect(plan.onSchedule, isTrue);
    expect(plan.onceCycleStartedAt, isNotNull);
    expect(await skips.forPlan(plan.uuid), isEmpty);

    final items = suggestTodayItems(
      plans: [plan],
      completedNewestFirst: await sessions.completedNewestFirst(),
      skips: await skips.all(),
      now: DateTime.utc(2026, 2, 1, 18),
    );
    expect(items, hasLength(1));
    expect(items.single.day!.dayId, 'day-1');
  });

  test('finishing the restarted cycle parks again', () async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final skips = MemorySkipRepository();
    final plan = _oncePlan();
    await plans.save(plan);
    await restartOncePlan(
      plan: plan,
      plans: plans,
      skips: skips,
      now: DateTime.utc(2026, 3, 1),
    );
    await sessions.save(
      _completed(plan.uuid, 'day-1', at: DateTime.utc(2026, 3, 2)),
    );
    await sessions.save(
      _completed(plan.uuid, 'day-2', at: DateTime.utc(2026, 3, 3)),
    );

    await parkOncePlanByIdIfFinished(
      planId: plan.uuid,
      plans: plans,
      sessions: sessions,
      skips: skips,
    );
    final stored = await plans.byUuid(plan.uuid);
    expect(stored!.onSchedule, isFalse);
  });
}

WorkoutPlan _oncePlan() {
  final now = DateTime.utc(2026, 1, 1);
  return WorkoutPlan.create(
    title: 'Once',
    source: PlanSource.created,
    scheduleMode: ScheduleMode.once,
    onSchedule: true,
    createdAt: now,
    updatedAt: now,
    days: [
      for (var i = 1; i <= 2; i++)
        PlanDay.create(
          dayId: 'day-$i',
          title: 'Day $i',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b-$i',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-$i',
                  title: 'squat',
                  prescribedSets: 2,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
    ],
  )..uuid = 'once-1';
}

WorkoutSession _completed(
  String planId,
  String dayId, {
  DateTime? at,
}) {
  return WorkoutSession.create(
    planId: planId,
    planDayId: dayId,
    planTitleSnapshot: 'Once',
    dayTitleSnapshot: dayId,
    startedAt: at ?? DateTime.utc(2026, 1, 10),
    status: SessionStatus.completed,
  );
}
