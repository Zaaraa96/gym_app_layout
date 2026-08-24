import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/single_plan/single_plan_model.dart';
import 'package:isar/isar.dart';

/// Step 1: one Isar instance with the v1 schemas can persist a nested plan
/// and a session snapshot, including the indexed lookups progress will use.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    try {
      // Host tests download the binary. Device runs already have it from
      // isar_flutter_libs; flutter_test also stubs HttpClient after a binding.
      await Isar.initializeIsarCore(download: true);
    } on IsarError {
      // Continue; Isar.open will fail loudly if the native lib is missing.
    }
    tempDir = await Directory.systemTemp.createTemp('gym_app_isar_');
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

  Future<Isar> openIsar() async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'isar$instanceSeq',
    );
    Get.put(service);
    return service.isar;
  }

  test(
      'opens the production schemas and round-trips a nested plan and session',
      () async {
    final isar = await openIsar();
    final now = DateTime.utc(2026, 8, 24, 12);

    final plan = _samplePlan(now);
    await isar.writeTxn(() async {
      await isar.workoutPlans.put(plan);
    });

    final loadedPlan = await isar.workoutPlans.get(plan.id);
    expect(loadedPlan, isNotNull);
    expect(loadedPlan!.title, 'plan 1');
    expect(loadedPlan.source, PlanSource.imported);
    expect(loadedPlan.days, hasLength(1));

    final day = loadedPlan.days.single;
    expect(day.dayId, 'day-1');
    expect(day.title, 'day 1- 4sar');
    expect(day.blocks, hasLength(2));
    expect(day.blocks[0].kind, BlockKind.superset);
    expect(day.blocks[0].exercises.map((e) => e.title),
        ['kang squat', 'leg extension']);
    expect(day.blocks[0].exercises.first.prescribedReps, 12);
    expect(day.blocks[0].exercises.first.prescribedDurationSeconds, isNull);
    expect(day.blocks[1].kind, BlockKind.single);
    expect(day.blocks[1].svgPath, 'assets/image/upper-body.svg');

    final abs = loadedPlan.commonSections.single;
    expect(abs.sectionId, 'sec-abs');
    expect(abs.title, 'abs');
    expect(abs.blocks.single.exercises.single.prescribedDurationSeconds, 30);
    expect(abs.blocks.single.exercises.single.prescribedReps, isNull);

    final session = _sampleSession(planId: plan.id, startedAt: now);
    await isar.writeTxn(() async {
      await isar.workoutSessions.put(session);
    });

    final loadedSession = await isar.workoutSessions.get(session.id);
    expect(loadedSession, isNotNull);
    expect(loadedSession!.planTitleSnapshot, 'plan 1');
    expect(loadedSession.dayTitleSnapshot, 'day 1- 4sar');
    expect(loadedSession.includedCommonSectionIds, ['sec-abs']);
    expect(loadedSession.status, SessionStatus.inProgress);
    expect(loadedSession.exerciseLogs, hasLength(2));

    final squatLog = loadedSession.exerciseLogs.first;
    expect(squatLog.exerciseTitleKey, exerciseTitleKeyFor('Kang Squat'));
    expect(squatLog.fromCommonSection, isFalse);
    expect(squatLog.isComplete, isFalse);
    expect(squatLog.sets, hasLength(1));
    expect(squatLog.sets.single.weightKg, 40);
    expect(squatLog.sets.single.reps, 12);

    final holdLog = loadedSession.exerciseLogs.last;
    expect(holdLog.fromCommonSection, isTrue);
    expect(holdLog.prescribedDurationSeconds, 30);
    expect(holdLog.sets.single.durationSeconds, 32);
    expect(holdLog.difficulty, 2);
    expect(holdLog.isComplete, isTrue);

    final monthStart = DateTime.utc(2026, 8, 1);
    final monthEnd = DateTime.utc(2026, 8, 31, 23, 59, 59);
    final byPlan =
        await isar.workoutSessions.where().planIdEqualTo(plan.id).findAll();
    expect(byPlan, hasLength(1));

    final inMonth = await isar.workoutSessions
        .where()
        .startedAtBetween(monthStart, monthEnd)
        .filter()
        .statusEqualTo(SessionStatus.inProgress)
        .findAll();
    expect(inMonth.map((s) => s.id), [session.id]);

    await isar.writeTxn(() async {
      loadedPlan.title = 'edited later';
      await isar.workoutPlans.put(loadedPlan);
    });
    final sessionAfterEdit = await isar.workoutSessions.get(session.id);
    expect(sessionAfterEdit!.planTitleSnapshot, 'plan 1');

    await isar.writeTxn(() async {
      await isar.singlePlanModels
          .put(SinglePlanModel(title: 'legacy', dayPlans: []));
    });
    final legacy = await isar.singlePlanModels.where().findAll();
    expect(legacy.single.title, 'legacy');
  });
}

WorkoutPlan _samplePlan(DateTime now) {
  return WorkoutPlan.create(
    title: 'plan 1',
    source: PlanSource.imported,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'day 1- 4sar',
        summary: 'upper body',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-ss',
            kind: BlockKind.superset,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-kang',
                title: 'kang squat',
                prescribedSets: 3,
                prescribedReps: 12,
              ),
              ExercisePrescription.create(
                prescriptionId: 'p-leg',
                title: 'leg extension',
                prescribedSets: 3,
                prescribedReps: 12,
              ),
            ],
          ),
          ExerciseBlock.create(
            blockId: 'block-single',
            kind: BlockKind.single,
            svgPath: 'assets/image/upper-body.svg',
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-lunge',
                title: 'reverse lunges+ Press',
                prescribedSets: 3,
                prescribedReps: 12,
              ),
            ],
          ),
        ],
      ),
    ],
    commonSections: [
      CommonSection.create(
        sectionId: 'sec-abs',
        title: 'abs',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-abs',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-shoot',
                title: 'shoot out',
                prescribedSets: 1,
                prescribedDurationSeconds: 30,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

WorkoutSession _sampleSession({
  required int planId,
  required DateTime startedAt,
}) {
  return WorkoutSession.create(
    planId: planId,
    planDayId: 'day-1',
    planTitleSnapshot: 'plan 1',
    dayTitleSnapshot: 'day 1- 4sar',
    startedAt: startedAt,
    status: SessionStatus.inProgress,
    includedCommonSectionIds: ['sec-abs'],
    exerciseLogs: [
      ExerciseLog.create(
        prescriptionId: 'p-kang',
        blockId: 'block-ss',
        blockKind: BlockKind.superset,
        fromCommonSection: false,
        exerciseTitle: 'kang squat',
        exerciseTitleKey: exerciseTitleKeyFor('Kang Squat'),
        prescribedSets: 3,
        prescribedReps: 12,
        sets: [
          SetLog.create(
            setIndex: 1,
            completedAt: startedAt,
            reps: 12,
            weightKg: 40,
          ),
        ],
      ),
      ExerciseLog.create(
        prescriptionId: 'p-shoot',
        blockId: 'block-abs',
        blockKind: BlockKind.single,
        fromCommonSection: true,
        exerciseTitle: 'shoot out',
        exerciseTitleKey: exerciseTitleKeyFor('shoot out'),
        prescribedSets: 1,
        prescribedDurationSeconds: 30,
        difficulty: 2,
        completedAt: startedAt,
        sets: [
          SetLog.create(
            setIndex: 1,
            completedAt: startedAt,
            durationSeconds: 32,
          ),
        ],
      ),
    ],
  );
}
