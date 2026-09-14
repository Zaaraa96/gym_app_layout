import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_plan_repository.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/isar_session_repository.dart';
import 'package:gym_app/data/isar_skip_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/once_plan_cycle.dart';
import 'package:gym_app/domain/plan_progress.dart';
import 'package:gym_app/domain/today_suggestion.dart';

import '../helpers/isar_core.dart';

/// Reproduces UI skip → Progress Skipped with real Isar (not MemorySkipRepository).
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_skip_once_');
  });

  tearDown(() async {
    if (Get.isRegistered<IsarService>()) {
      await IsarService.to.close(deleteFromDisk: true);
    }
    Get.reset();
  });

  tearDownAll(() async {
    final dir = tempDir;
    if (dir != null && dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('skip both once days: forPlan + Progress mark Skipped and park', () async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'skipOnce$instanceSeq',
    );
    Get.put(service);
    final plans = IsarPlanRepository(service.isar);
    final sessions = IsarSessionRepository(service.isar);
    final skips = IsarSkipRepository(service.isar);

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

    // Simulate Today Skip day twice (same as plans_home_page._skipDay).
    for (final dayId in ['day-1', 'day-2']) {
      await skips.save(
        PlanDaySkip.create(
          planId: plan.uuid,
          dayId: dayId,
          date: DateTime.now(),
        ),
      );
      await parkOncePlanByIdIfFinished(
        planId: plan.uuid,
        plans: plans,
        sessions: sessions,
        skips: skips,
      );
    }

    final all = await skips.all();
    final forPlan = await skips.forPlan(plan.uuid);
    expect(all, hasLength(2), reason: 'skips.all should see both rows');
    expect(forPlan, hasLength(2), reason: 'skips.forPlan must match all()');

    final stored = await plans.byUuid(plan.uuid);
    expect(stored!.onSchedule, isFalse);

    final progress = await loadPlanProgress(
      plan: stored,
      sessions: sessions,
      skips: skips,
    );
    expect(progress.skippedCount, 2);
    expect(progress.leftCount, 0);
    expect(progress.isFinishedOnce, isTrue);
    expect(
      progress.dayStates.values.toSet(),
      {PlanDayProgressState.skipped},
    );

    final overview = await loadHomeOverview(
      plans: plans,
      sessions: sessions,
      skips: skips,
    );
    expect(overview.todayItems, isEmpty);
    expect(overview.plans.single.onSchedule, isFalse);
  });
}
