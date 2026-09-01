import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/session_lifecycle.dart';

void main() {
  test('memory plans assign uuid, mark dirty, and list newest first', () async {
    final plans = MemoryPlanRepository();
    final older = WorkoutPlan.create(
      uuid: 'older',
      title: 'older',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final newer = WorkoutPlan.create(
      uuid: 'newer',
      title: 'newer',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 2, 1),
      updatedAt: DateTime.utc(2026, 2, 1),
    );
    await plans.putSynced(older);
    await plans.putSynced(newer);
    expect((await plans.all()).map((plan) => plan.uuid), ['newer', 'older']);

    older.title = 'edited';
    await plans.save(older);
    expect(older.dirty, isTrue);
    expect((await plans.unsynced()).map((plan) => plan.id), [older.id]);
    expect((await plans.byUuid('older'))?.title, 'edited');
  });

  test('memory lastCompleted keys off plan uuid, not the row id', () async {
    final sessions = MemorySessionRepository();
    const planUuid = 'plan-uuid-not-the-isar-id';
    final older = WorkoutSession.create(
      planId: planUuid,
      planDayId: 'd1',
      planTitleSnapshot: 'plan',
      dayTitleSnapshot: 'day',
      startedAt: DateTime.utc(2026, 1, 1),
      status: SessionStatus.completed,
    );
    older.id = 99;
    final newer = WorkoutSession.create(
      planId: planUuid,
      planDayId: 'd1',
      planTitleSnapshot: 'plan',
      dayTitleSnapshot: 'day',
      startedAt: DateTime.utc(2026, 2, 1),
      status: SessionStatus.completed,
    );
    newer.id = 1;
    await sessions.putSynced(older);
    await sessions.putSynced(newer);

    final last = await sessions.lastCompleted(planId: planUuid);
    expect(last?.startedAt, DateTime.utc(2026, 2, 1));
    expect(await sessions.lastCompleted(planId: '99'), isNull);
  });

  test('memory lifecycle start snapshots the day and forbids a second live',
      () async {
    final sessions = MemorySessionRepository();
    final lifecycle = SessionLifecycle(sessions);
    final plan = WorkoutPlan.create(
      title: 'plan',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      days: [
        PlanDay.create(
          dayId: 'd1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p1',
                  title: 'Squat',
                  prescribedSets: 3,
                  prescribedReps: 8,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    plan.id = 1;

    final live = await lifecycle.start(plan: plan, planDayId: 'd1');
    expect(live.status, SessionStatus.inProgress);
    expect(live.planId, plan.uuid);
    expect(live.exerciseLogs, hasLength(1));
    expect(await sessions.inProgress(), isNotNull);

    expect(
      () => lifecycle.start(plan: plan, planDayId: 'd1'),
      throwsStateError,
    );
  });
}
