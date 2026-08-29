import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_repository.dart';

import '../helpers/isar_core.dart';

/// Step 4: [SessionRepository] is the only writer for sessions, including
/// month queries and the one in-progress lookup.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_sessions_');
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

  Future<({PlanRepository plans, SessionRepository sessions})> open() async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'sessions$instanceSeq',
    );
    Get.put(service);
    return (
      plans: PlanRepository(service.isar),
      sessions: SessionRepository(service.isar),
    );
  }

  test('start snapshots day blocks then included common sections', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    final session = await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      includedCommonSectionIds: const ['sec-abs'],
      startedAt: DateTime.utc(2026, 8, 15, 10),
    );

    expect(session.status, SessionStatus.inProgress);
    expect(session.planTitleSnapshot, 'plan 1');
    expect(session.dayTitleSnapshot, 'day 1- 4sar');
    expect(session.includedCommonSectionIds, ['sec-abs']);
    expect(session.exerciseLogs.map((l) => l.exerciseTitle), [
      'kang squat',
      'leg extension',
      'shoot out',
    ]);
    expect(session.exerciseLogs[0].fromCommonSection, isFalse);
    expect(session.exerciseLogs[0].blockKind, BlockKind.superset);
    expect(session.exerciseLogs[2].fromCommonSection, isTrue);
    expect(session.exerciseLogs[2].prescribedDurationSeconds, 30);
    expect(session.exerciseLogs[2].exerciseTitleKey, 'shoot out');
  });

  test('inProgress returns the live session and ignore abandoned', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    expect(await db.sessions.inProgress(), isNull);

    final live = await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
    );
    expect((await db.sessions.inProgress())?.id, live.id);

    await db.sessions.abandonInProgress(endedAt: DateTime.utc(2026, 8, 15, 11));
    expect(await db.sessions.inProgress(), isNull);

    final stored = await db.sessions.byId(live.id);
    expect(stored!.status, SessionStatus.abandoned);
    expect(
      stored.endedAt!.isAtSameMomentAs(DateTime.utc(2026, 8, 15, 11)),
      isTrue,
    );
  });

  test('forMonth keeps in-progress and completed, drops abandoned and other months',
      () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    Future<WorkoutSession> add({
      required DateTime startedAt,
      required SessionStatus status,
    }) async {
      final session = await db.sessions.start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: startedAt,
      );
      session.status = status;
      if (status != SessionStatus.inProgress) {
        session.endedAt = startedAt.add(const Duration(hours: 1));
      }
      await db.sessions.save(session);
      return session;
    }

    final inProgress = await add(
      startedAt: DateTime.utc(2026, 8, 1, 8),
      status: SessionStatus.inProgress,
    );
    final completed = await add(
      startedAt: DateTime.utc(2026, 8, 20, 18),
      status: SessionStatus.completed,
    );
    await add(
      startedAt: DateTime.utc(2026, 8, 10, 12),
      status: SessionStatus.abandoned,
    );
    await add(
      startedAt: DateTime.utc(2026, 7, 31, 23, 59),
      status: SessionStatus.completed,
    );
    await add(
      startedAt: DateTime.utc(2026, 9, 1),
      status: SessionStatus.completed,
    );

    final august = await db.sessions.forMonth(DateTime.utc(2026, 8));
    expect(august.map((s) => s.id), [inProgress.id, completed.id]);
  });

  test('forCalendarDay lists that day’s sessions oldest first', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    final later = await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 18),
    );
    later.status = SessionStatus.completed;
    later.endedAt = DateTime.utc(2026, 8, 15, 19);
    await db.sessions.save(later);

    final earlier = await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 7),
    );
    earlier.status = SessionStatus.completed;
    earlier.endedAt = DateTime.utc(2026, 8, 15, 8);
    await db.sessions.save(earlier);

    await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 16, 7),
    );

    final day = await db.sessions.forCalendarDay(DateTime.utc(2026, 8, 15));
    expect(day.map((s) => s.id), [earlier.id, later.id]);
  });

  test('lastCompleted is the newest completed session for that plan', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    final first = await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 10, 8),
    );
    first.status = SessionStatus.completed;
    first.endedAt = DateTime.utc(2026, 8, 10, 9);
    await db.sessions.save(first);

    final second = await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 12, 8),
    );
    second.status = SessionStatus.completed;
    second.endedAt = DateTime.utc(2026, 8, 12, 9);
    await db.sessions.save(second);

    await db.sessions.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 13, 8),
    );

    expect((await db.sessions.lastCompleted(planId: plan.id))?.id, second.id);
    expect(
      (await db.sessions.completedNewestFirst(planId: plan.id)).map((s) => s.id),
      [second.id, first.id],
    );
  });
}

WorkoutPlan _plan() {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'plan 1',
    source: PlanSource.imported,
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
