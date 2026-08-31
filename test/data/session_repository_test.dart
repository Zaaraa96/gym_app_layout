import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_plan_repository.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/isar_session_repository.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_lifecycle.dart';
import 'package:gym_app/data/session_repository.dart';

import '../helpers/isar_core.dart';

/// [IsarSessionRepository] queries plus [SessionLifecycle] start/abandon rules.
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

  Future<
      ({
        PlanRepository plans,
        SessionRepository sessions,
        SessionLifecycle lifecycle,
      })> open() async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'sessions$instanceSeq',
    );
    Get.put(service);
    final sessions = IsarSessionRepository(service.isar);
    return (
      plans: IsarPlanRepository(service.isar),
      sessions: sessions,
      lifecycle: SessionLifecycle(sessions),
    );
  }

  test('start snapshots day blocks then included common sections', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    final session = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      includedCommonSectionIds: const ['sec-abs'],
      startedAt: DateTime.utc(2026, 8, 15, 10),
    );

    expect(session.status, SessionStatus.inProgress);
    expect(session.planId, plan.uuid);
    expect(session.uuid, isNotEmpty);
    expect(session.dirty, isTrue);
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

    final live = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
    );
    expect((await db.sessions.inProgress())?.id, live.id);

    await db.lifecycle
        .abandonInProgress(endedAt: DateTime.utc(2026, 8, 15, 11));
    expect(await db.sessions.inProgress(), isNull);

    final stored = await db.sessions.byId(live.id);
    expect(stored!.status, SessionStatus.abandoned);
    expect(
      stored.endedAt!.isAtSameMomentAs(DateTime.utc(2026, 8, 15, 11)),
      isTrue,
    );
  });

  test(
      'forMonth keeps in-progress and completed, drops abandoned and other months',
      () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    Future<WorkoutSession> add({
      required DateTime startedAt,
      required SessionStatus status,
    }) async {
      final session = await db.lifecycle.start(
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
    final inProgress = await add(
      startedAt: DateTime.utc(2026, 8, 1, 8),
      status: SessionStatus.inProgress,
    );

    final august = await db.sessions.forMonth(DateTime.utc(2026, 8));
    expect(august.map((s) => s.id), [inProgress.id, completed.id]);
  });

  test('forCalendarDay lists that day’s sessions oldest first', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    final later = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 18),
    );
    later.status = SessionStatus.completed;
    later.endedAt = DateTime.utc(2026, 8, 15, 19);
    await db.sessions.save(later);

    final earlier = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 7),
    );
    earlier.status = SessionStatus.completed;
    earlier.endedAt = DateTime.utc(2026, 8, 15, 8);
    await db.sessions.save(earlier);

    await db.lifecycle.start(
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

    final first = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 10, 8),
    );
    first.status = SessionStatus.completed;
    first.endedAt = DateTime.utc(2026, 8, 10, 9);
    await db.sessions.save(first);

    final second = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 12, 8),
    );
    second.status = SessionStatus.completed;
    second.endedAt = DateTime.utc(2026, 8, 12, 9);
    await db.sessions.save(second);

    await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 13, 8),
    );

    expect((await db.sessions.lastCompleted(planId: plan.uuid))?.id, second.id);
    expect(
      (await db.sessions.completedNewestFirst(planId: plan.uuid))
          .map((s) => s.id),
      [second.id, first.id],
    );

    await expectLater(
      db.lifecycle.start(plan: plan, planDayId: 'day-1'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already in progress'),
        ),
      ),
    );
  });

  test('start throws when the day is not on the plan', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    await expectLater(
      db.lifecycle.start(plan: plan, planDayId: 'missing'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Day not on this plan'),
        ),
      ),
    );
  });

  test('unknown common section ids are skipped and omitted commons stay out',
      () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);

    final withoutCommons = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
    );
    expect(
      withoutCommons.exerciseLogs.map((l) => l.exerciseTitle),
      ['kang squat', 'leg extension'],
    );

    withoutCommons.status = SessionStatus.abandoned;
    withoutCommons.endedAt = DateTime.utc(2026, 8, 15, 11);
    await db.sessions.save(withoutCommons);

    final withUnknown = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      includedCommonSectionIds: const ['sec-abs', 'sec-missing'],
      startedAt: DateTime.utc(2026, 8, 16, 10),
    );
    expect(
      withUnknown.exerciseLogs.map((l) => l.exerciseTitle),
      ['kang squat', 'leg extension', 'shoot out'],
    );
    expect(withUnknown.includedCommonSectionIds, ['sec-abs', 'sec-missing']);
  });

  test('completedNewestFirst without a plan id is what home uses', () async {
    final db = await open();
    final plan = _plan();
    await db.plans.save(plan);
    final other = WorkoutPlan.create(
      title: 'plan 2',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 2),
      days: plan.days,
    );
    await db.plans.save(other);

    Future<WorkoutSession> complete({
      required WorkoutPlan onPlan,
      required DateTime at,
    }) async {
      final session = await db.lifecycle.start(
        plan: onPlan,
        planDayId: 'day-1',
        startedAt: at,
      );
      session.status = SessionStatus.completed;
      session.endedAt = at.add(const Duration(hours: 1));
      await db.sessions.save(session);
      return session;
    }

    final older = await complete(
      onPlan: plan,
      at: DateTime.utc(2026, 8, 10, 8),
    );
    final newer = await complete(
      onPlan: other,
      at: DateTime.utc(2026, 8, 12, 8),
    );
    await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 13, 8),
    );

    expect(
      (await db.sessions.completedNewestFirst()).map((s) => s.id),
      [newer.id, older.id],
    );
    expect((await db.sessions.lastCompleted())?.id, newer.id);
  });

  test('abandonInProgress is a no-op when nothing is live', () async {
    final db = await open();
    await db.lifecycle.abandonInProgress(
      endedAt: DateTime.utc(2026, 8, 15, 11),
    );
    expect(await db.sessions.inProgress(), isNull);
  });

  test('exerciseLogsForStart copies day blocks then included commons', () {
    final plan = _plan();
    final empty = exerciseLogsForStart(
      day: plan.days.single,
      commonSections: plan.commonSections,
      includedCommonSectionIds: const [],
    );
    expect(empty.map((log) => log.exerciseTitle), ['kang squat', 'leg extension']);
    expect(empty.every((log) => log.fromCommonSection == false), isTrue);

    final withAbs = exerciseLogsForStart(
      day: plan.days.single,
      commonSections: plan.commonSections,
      includedCommonSectionIds: const ['sec-missing', 'sec-abs'],
    );
    expect(
      withAbs.map((log) => log.exerciseTitle),
      ['kang squat', 'leg extension', 'shoot out'],
    );
    expect(withAbs.last.fromCommonSection, isTrue);
    expect(withAbs.last.prescribedDurationSeconds, 30);
    expect(withAbs.last.exerciseTitleKey, 'shoot out');
  });

  test('save marks dirty and bumps time; putSynced clears dirty and keeps time',
      () async {
    final db = await open();
    final plan = _plan();
    final original = DateTime.utc(2026, 8, 1, 8);
    plan.updatedAt = original;
    plan.dirty = false;
    plan.id = await db.plans.putSynced(plan);

    expect(plan.dirty, isFalse);
    expect(plan.updatedAt.isAtSameMomentAs(original), isTrue);

    await db.plans.save(plan);
    expect(plan.dirty, isTrue);
    expect(plan.updatedAt.isAfter(original), isTrue);
    final stamped = plan.updatedAt;
    expect((await db.plans.unsynced()).map((row) => row.id), [plan.id]);

    await db.plans.putSynced(plan);
    expect(plan.dirty, isFalse);
    expect(plan.updatedAt.isAtSameMomentAs(stamped), isTrue);
    expect(await db.plans.unsynced(), isEmpty);
    expect((await db.plans.byUuid(plan.uuid))!.id, plan.id);

    final session = await db.lifecycle.start(
      plan: plan,
      planDayId: 'day-1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
    );
    expect(session.planId, plan.uuid);
    expect(session.dirty, isTrue);
    expect((await db.sessions.unsynced()).map((row) => row.id), [session.id]);
    expect((await db.sessions.byUuid(session.uuid))!.id, session.id);

    final sessionStamp = session.updatedAt;
    await db.sessions.putSynced(session);
    expect(session.dirty, isFalse);
    expect(session.updatedAt.isAtSameMomentAs(sessionStamp), isTrue);
    expect(await db.sessions.unsynced(), isEmpty);
  });

  test('empty uuid is filled on save so byUuid can find the row', () async {
    final db = await open();
    final plan = _plan()..uuid = '';
    await db.plans.save(plan);
    expect(plan.uuid, isNotEmpty);
    expect((await db.plans.byUuid(plan.uuid))!.id, plan.id);

    final session = WorkoutSession.create(
      uuid: '',
      planId: plan.uuid,
      planDayId: 'day-1',
      planTitleSnapshot: plan.title,
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
      status: SessionStatus.completed,
    );
    await db.sessions.save(session);
    expect(session.uuid, isNotEmpty);
    expect((await db.sessions.byUuid(session.uuid))!.id, session.id);
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
