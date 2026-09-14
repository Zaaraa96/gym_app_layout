import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/app/app_routes.dart';
import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/isar_skip_repository.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/memory_skip_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/once_plan_cycle.dart';
import 'package:gym_app/domain/plan_progress.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_lifecycle.dart';
import 'package:gym_app/domain/session_repository.dart';
import 'package:gym_app/domain/skip_repository.dart';
import 'package:gym_app/domain/today_suggestion.dart';

/// Reproduces: Home and Plan pages must share the same SkipRepository.
void main() {
  tearDown(Get.reset);

  test('resolveAppPorts reuses registered SkipRepository (not a fresh Memory)',
      () {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final skips = MemorySkipRepository();
    Get.put<PlanRepository>(plans);
    Get.put<SessionRepository>(sessions);
    Get.put<SkipRepository>(skips);
    Get.put(SessionLifecycle(sessions));

    final home = resolveAppPorts();
    final planPage = resolveAppPorts();

    expect(identical(home.skips, skips), isTrue);
    expect(identical(planPage.skips, skips), isTrue);
    expect(home.skips, isNot(isA<IsarSkipRepository>()));
  });

  test('skip on home ports is visible to Progress on plan ports', () async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final skips = MemorySkipRepository();
    Get.put<PlanRepository>(plans);
    Get.put<SessionRepository>(sessions);
    Get.put<SkipRepository>(skips);
    Get.put(SessionLifecycle(sessions));

    final plan = WorkoutPlan.create(
      title: 'Once',
      source: PlanSource.created,
      scheduleMode: ScheduleMode.once,
      onSchedule: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
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
    );
    await plans.save(plan);

    // Simulate PlansHomePage vs PlanPage each calling resolveAppPorts().
    final homePorts = resolveAppPorts();
    final planPorts = resolveAppPorts();

    for (final dayId in ['day-1', 'day-2']) {
      await homePorts.skips.save(
        PlanDaySkip.create(
          planId: plan.uuid,
          dayId: dayId,
          date: DateTime.now(),
        ),
      );
      await parkOncePlanByIdIfFinished(
        planId: plan.uuid,
        plans: homePorts.plans,
        sessions: homePorts.sessions,
        skips: homePorts.skips,
      );
    }

    final overview = await loadHomeOverview(
      plans: homePorts.plans,
      sessions: homePorts.sessions,
      skips: homePorts.skips,
    );
    expect(overview.todayItems, isEmpty);
    expect((await plans.byUuid(plan.uuid))!.onSchedule, isFalse);

    final progress = await loadPlanProgress(
      plan: (await planPorts.plans.byUuid(plan.uuid))!,
      sessions: planPorts.sessions,
      skips: planPorts.skips,
    );
    expect(progress.skippedCount, 2);
    expect(progress.leftCount, 0);
    expect(progress.isFinishedOnce, isTrue);
  });
}
