import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_plan_repository.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/isar_session_repository.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/session_lifecycle.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/features/workout/workout_controller.dart';

import '../helpers/isar_core.dart';

/// Step 4: [WorkoutController] owns live session state and persists each log.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_workout_');
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

  Future<({SessionRepository sessions, WorkoutController controller})>
      startController({
    WorkoutPlan? plan,
    List<String> commons = const ['sec-abs'],
  }) async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'workout$instanceSeq',
    );
    Get.put(service);
    final plans = IsarPlanRepository(service.isar);
    final sessions = IsarSessionRepository(service.isar);
    final stored = plan ?? _plan();
    await plans.save(stored);
    final session = await SessionLifecycle(sessions).start(
      plan: stored,
      planDayId: stored.days.first.dayId,
      includedCommonSectionIds: commons,
      startedAt: DateTime.utc(2026, 8, 26, 12),
    );
    final controller = WorkoutController(
      sessionId: session.id,
      sessions: sessions,
      clock: () => DateTime.utc(2026, 8, 26, 12, 5),
    );
    await controller.load();
    addTearDown(controller.onClose);
    return (sessions: sessions, controller: controller);
  }

  test(
      'a superset alternates prescribed sets and forbids rating until both are done',
      () async {
    final started = await startController();
    final c = started.controller;

    expect(c.activeLog?.exerciseTitle, 'kang squat');
    expect(c.isPrescribedPhase, isTrue);
    expect(c.canRate(c.session!.exerciseLogs[0]), isFalse);

    await c.logSet(reps: 12, weightKg: 40);
    expect(c.activeLog?.exerciseTitle, 'leg extension');
    await expectLater(
      c.logSet(reps: 10, log: c.session!.exerciseLogs[0]),
      throwsA(isA<WorkoutActionException>()),
    );

    await c.logSet(reps: 12);
    expect(c.activeLog?.exerciseTitle, 'kang squat');
    await c.logSet(reps: 10);
    await c.logSet(reps: 10);
    await c.logSet(reps: 8);
    await c.logSet(reps: 8);

    expect(c.isPrescribedPhase, isFalse);
    expect(c.inExtrasPhase, isTrue);
    expect(c.session!.exerciseLogs[0].sets, hasLength(3));
    expect(c.session!.exerciseLogs[1].sets, hasLength(3));
    expect(c.canRate(c.session!.exerciseLogs[0]), isTrue);
    expect(c.canRate(c.session!.exerciseLogs[1]), isTrue);

    await c.logSet(reps: 6, log: c.session!.exerciseLogs[0]);
    expect(c.session!.exerciseLogs[0].sets, hasLength(4));
    expect(c.session!.exerciseLogs[0].sets.last.setIndex, 4);

    await c.rate(3, log: c.session!.exerciseLogs[0]);
    expect(c.session!.exerciseLogs[0].isComplete, isTrue);
    expect(c.canLogSet(c.session!.exerciseLogs[0]), isFalse);
    expect(c.activeLog?.exerciseTitle, 'leg extension');
    expect(c.canRate(c.session!.exerciseLogs[1]), isTrue);

    await c.logSet(reps: 4, log: c.session!.exerciseLogs[1]);
    expect(c.session!.exerciseLogs[1].sets, hasLength(4));
    expect(c.canRate(c.session!.exerciseLogs[1]), isTrue);
  });

  test('a single stays active through extras until it is rated', () async {
    final started = await startController(
      plan: _singlePlan(),
      commons: const [],
    );
    final c = started.controller;
    expect(c.activeLog?.exerciseTitle, 'push up');

    await c.logSet(reps: 10);
    await c.logSet(reps: 10);
    expect(c.isPrescribedPhase, isFalse);
    expect(c.activeLog?.exerciseTitle, 'push up');
    expect(c.canRate(c.activeLog!), isTrue);

    await c.logSet(reps: 8);
    expect(c.activeLog?.sets, hasLength(3));
    expect(c.activeLog?.exerciseTitle, 'push up');

    await c.rate(4);
    expect(c.session!.exerciseLogs.single.isComplete, isTrue);
    expect(c.session!.status, SessionStatus.completed);
    expect(c.activeLog, isNull);
    expect(c.canLogSet(c.session!.exerciseLogs.single), isFalse);
  });

  test('duration log stores prescribed if the timer never started', () async {
    final started = await startController();
    final c = started.controller;
    for (var i = 0; i < 6; i++) {
      await c.logSet(reps: 12);
    }
    await c.rate(3, log: c.session!.exerciseLogs[0]);
    await c.rate(3, log: c.session!.exerciseLogs[1]);

    expect(c.activeLog?.exerciseTitle, 'shoot out');
    expect(c.durationRemainingSeconds, 30);
    expect(c.durationTimerStarted, isFalse);
    await c.logTime();
    expect(c.activeLog?.sets.single.durationSeconds, 30);
  });

  test('duration log stores elapsed including overtime after the timer runs',
      () async {
    final started = await startController();
    final c = started.controller;
    for (var i = 0; i < 6; i++) {
      await c.logSet(reps: 12);
    }
    await c.rate(3, log: c.session!.exerciseLogs[0]);
    await c.rate(3, log: c.session!.exerciseLogs[1]);

    c.startDurationCountdown();
    c.debugAdvanceDuration(35);
    await c.logTime();
    expect(c.session!.exerciseLogs.last.sets.single.durationSeconds, 35);
  });

  test('each logged set is written so a new controller can resume', () async {
    final started = await startController();
    final c = started.controller;
    await c.logSet(reps: 12, weightKg: 40);
    c.onClose();

    final resumed = WorkoutController(
      sessionId: c.sessionId,
      sessions: started.sessions,
    );
    await resumed.load();
    addTearDown(resumed.onClose);

    expect(resumed.activeLog?.exerciseTitle, 'leg extension');
    expect(resumed.session!.exerciseLogs.first.sets.single.weightKg, 40);
    expect(resumed.session!.status, SessionStatus.inProgress);
  });

  test('rest is manual and is not persisted', () async {
    final started = await startController();
    final c = started.controller;
    expect(c.isResting, isFalse);
    c.startRest();
    expect(c.isResting, isTrue);
    expect(c.restElapsedSeconds, 0);
    c.resetRest();
    expect(c.isResting, isFalse);

    await c.logSet(reps: 12);
    final stored = await started.sessions.byId(c.sessionId);
    expect(stored!.exerciseLogs.first.sets, hasLength(1));
  });

  test('finish marks the session completed', () async {
    final started = await startController();
    await started.controller.logSet(reps: 12);
    await started.controller.finish();
    expect(started.controller.session!.status, SessionStatus.completed);
    expect(started.controller.session!.endedAt, isNotNull);
    expect(await started.sessions.inProgress(), isNull);
  });

  test('discard marks the session abandoned', () async {
    final started = await startController();
    await started.controller.discard();
    expect(started.controller.session!.status, SessionStatus.abandoned);
    expect(await started.sessions.inProgress(), isNull);
  });

  test('reps are required and weight may be omitted', () async {
    final started = await startController();
    final c = started.controller;
    await expectLater(c.logSet(), throwsA(isA<WorkoutActionException>()));
    await c.logSet(reps: 12);
    expect(c.session!.exerciseLogs.first.sets.single.weightKg, isNull);
    expect(c.session!.exerciseLogs.first.sets.single.reps, 12);
  });

  test('rating must be 1 to 5 and is blocked until prescribed sets are done',
      () async {
    final started = await startController();
    final c = started.controller;
    await expectLater(
      c.rate(0),
      throwsA(
        isA<WorkoutActionException>().having(
          (e) => e.message,
          'message',
          contains('from 1 to 5'),
        ),
      ),
    );
    await expectLater(c.rate(6), throwsA(isA<WorkoutActionException>()));
    await expectLater(
      c.rate(3),
      throwsA(
        isA<WorkoutActionException>().having(
          (e) => e.message,
          'message',
          contains('prescribed sets'),
        ),
      ),
    );
    await expectLater(c.logTime(), throwsA(isA<WorkoutActionException>()));
  });

  test('extras may be logged on a sibling in the same block', () async {
    final started = await startController();
    final c = started.controller;
    for (var i = 0; i < 6; i++) {
      await c.logSet(reps: 12);
    }
    expect(c.inExtrasPhase, isTrue);
    expect(c.activeLog?.exerciseTitle, 'leg extension');

    await c.logSet(reps: 6, log: c.session!.exerciseLogs[0]);
    expect(c.session!.exerciseLogs[0].sets, hasLength(4));
    expect(c.session!.exerciseLogs[0].sets.last.reps, 6);
    expect(c.activeLog?.exerciseTitle, 'kang squat');

    await expectLater(
      c.logSet(reps: 5, log: c.session!.exerciseLogs[2]),
      throwsA(isA<WorkoutActionException>()),
    );
  });

  test('load fails when the session is gone, and ended sessions reject logs',
      () async {
    final started = await startController();
    await started.controller.finish();
    await expectLater(
      started.controller.logSet(reps: 10),
      throwsA(
        isA<WorkoutActionException>().having(
          (e) => e.message,
          'message',
          contains('already ended'),
        ),
      ),
    );

    final missing = WorkoutController(
      sessionId: 999999,
      sessions: started.sessions,
    );
    addTearDown(missing.onClose);
    await expectLater(
      missing.load(),
      throwsA(
        isA<WorkoutActionException>().having(
          (e) => e.message,
          'message',
          contains('no longer here'),
        ),
      ),
    );
  });

  test('the duration timer ticks remaining seconds without debugAdvance',
      () async {
    final started = await startController();
    final c = started.controller;
    await _reachDurationHold(c);

    fakeAsync((async) {
      c.startDurationCountdown();
      expect(c.isDurationRunning, isTrue);
      expect(c.durationRemainingSeconds, 30);
      async.elapse(const Duration(seconds: 2));
      expect(c.durationRemainingSeconds, 28);
      async.elapse(const Duration(seconds: 30));
      expect(c.durationRemainingSeconds, -2);
      c.startDurationCountdown();
      expect(c.durationRemainingSeconds, -2);
      c.onClose();
    });
  });

  test('logging time on a sibling uses prescribed seconds, not the active timer',
      () async {
    final started = await startController(
      plan: _twoHoldsPlan(),
      commons: const [],
    );
    final c = started.controller;
    await c.logTime();
    await c.logTime();
    expect(c.inExtrasPhase, isTrue);
    expect(c.activeLog?.exerciseTitle, 'hollow hold');

    c.startDurationCountdown();
    c.debugAdvanceDuration(8);
    await c.logTime(log: c.session!.exerciseLogs[0]);
    expect(c.session!.exerciseLogs[0].sets, hasLength(2));
    expect(c.session!.exerciseLogs[0].sets.last.durationSeconds, 30);
    expect(c.session!.exerciseLogs[1].sets, hasLength(1));
  });

  test('startDurationCountdown is a no-op on a reps exercise', () async {
    final started = await startController();
    final c = started.controller;
    expect(c.activeLog?.prescribedDurationSeconds, isNull);
    c.startDurationCountdown();
    expect(c.isDurationRunning, isFalse);
    expect(c.durationTimerStarted, isFalse);
    expect(c.durationRemainingSeconds, isNull);
  });

  test('discarded sessions reject logs and a second startRest is a no-op',
      () async {
    final started = await startController();
    final c = started.controller;
    c.startRest();
    expect(c.isResting, isTrue);
    c.startRest();
    expect(c.isResting, isTrue);
    expect(c.restElapsedSeconds, 0);

    await c.discard();
    await expectLater(
      c.logSet(reps: 10),
      throwsA(
        isA<WorkoutActionException>().having(
          (e) => e.message,
          'message',
          contains('already ended'),
        ),
      ),
    );
    await expectLater(
      c.finish(),
      throwsA(isA<WorkoutActionException>()),
    );
    expect(c.session!.status, SessionStatus.abandoned);
    expect(await started.sessions.inProgress(), isNull);
  });
}

Future<void> _reachDurationHold(WorkoutController c) async {
  for (var i = 0; i < 6; i++) {
    await c.logSet(reps: 12);
  }
  await c.rate(3, log: c.session!.exerciseLogs[0]);
  await c.rate(3, log: c.session!.exerciseLogs[1]);
  expect(c.activeLog?.exerciseTitle, 'shoot out');
}

WorkoutPlan _twoHoldsPlan() {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'holds',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'holds',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-holds',
            kind: BlockKind.superset,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-plank',
                title: 'plank',
                prescribedSets: 1,
                prescribedDurationSeconds: 30,
              ),
              ExercisePrescription.create(
                prescriptionId: 'p-hollow',
                title: 'hollow hold',
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

WorkoutPlan _singlePlan() {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'push',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'day 1',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-single',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-push',
                title: 'push up',
                prescribedSets: 2,
                prescribedReps: 10,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

WorkoutPlan _plan() {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'plan 1',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'day 1- 4sar',
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
