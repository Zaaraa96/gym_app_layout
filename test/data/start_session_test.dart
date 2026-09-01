import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/session_lifecycle.dart';
import 'package:gym_app/data/start_session.dart';

void main() {
  late MemorySessionRepository sessions;
  late SessionLifecycle lifecycle;
  late StartSession start;

  setUp(() {
    sessions = MemorySessionRepository();
    lifecycle = SessionLifecycle(sessions);
    start = StartSession(lifecycle, sessions);
  });

  test('starts a day with no live session and no commons', () async {
    final plan = _plan();
    final result = await start.run(
      plan: plan,
      planDayId: 'day-1',
      onConflict: (_) async => fail('no conflict'),
      onCommons: (_) async => fail('no commons'),
    );
    expect(result, isA<StartSessionOpened>());
    final session = (result as StartSessionOpened).session;
    expect(session.planDayId, 'day-1');
    expect(session.status, SessionStatus.inProgress);
    expect(session.exerciseLogs.map((log) => log.exerciseTitle), ['squat']);
    expect(await sessions.inProgress(), isNotNull);
  });

  test('same live day resumes without asking', () async {
    final plan = _plan();
    final existing = await lifecycle.start(plan: plan, planDayId: 'day-1');
    var asked = false;
    final result = await start.run(
      plan: plan,
      planDayId: 'day-1',
      onConflict: (_) async {
        asked = true;
        return LiveSessionChoice.cancel;
      },
      onCommons: (_) async => fail('no commons'),
    );
    expect(asked, isFalse);
    expect(result, isA<StartSessionOpened>());
    expect((result as StartSessionOpened).session.uuid, existing.uuid);
  });

  test('conflict resume returns the existing session', () async {
    final plan = _plan(dayTitles: ['Day 1', 'Day 2']);
    final existing = await lifecycle.start(plan: plan, planDayId: 'day-1');
    final result = await start.run(
      plan: plan,
      planDayId: 'day-2',
      onConflict: (live) async {
        expect(live.uuid, existing.uuid);
        return LiveSessionChoice.resumeExisting;
      },
      onCommons: (_) async => fail('should not ask commons'),
    );
    expect((result as StartSessionOpened).session.uuid, existing.uuid);
    expect((await sessions.inProgress())?.uuid, existing.uuid);
  });

  test('conflict cancel leaves the live session', () async {
    final plan = _plan(dayTitles: ['Day 1', 'Day 2']);
    final existing = await lifecycle.start(plan: plan, planDayId: 'day-1');
    final result = await start.run(
      plan: plan,
      planDayId: 'day-2',
      onConflict: (_) async => LiveSessionChoice.cancel,
      onCommons: (_) async => fail('should not ask commons'),
    );
    expect(result, isA<StartSessionCancelled>());
    expect((await sessions.inProgress())?.uuid, existing.uuid);
  });

  test('abandon and start closes the live session and opens the new day',
      () async {
    final plan = _plan(dayTitles: ['Day 1', 'Day 2']);
    final existing = await lifecycle.start(plan: plan, planDayId: 'day-1');
    final result = await start.run(
      plan: plan,
      planDayId: 'day-2',
      onConflict: (_) async => LiveSessionChoice.abandonAndStart,
      onCommons: (_) async => fail('no commons'),
    );
    expect(result, isA<StartSessionOpened>());
    final opened = (result as StartSessionOpened).session;
    expect(opened.uuid, isNot(existing.uuid));
    expect(opened.planDayId, 'day-2');
    expect((await sessions.byUuid(existing.uuid))?.status, SessionStatus.abandoned);
    expect((await sessions.inProgress())?.uuid, opened.uuid);
  });

  test('commons cancel does not start', () async {
    final plan = _plan(commons: true);
    final result = await start.run(
      plan: plan,
      planDayId: 'day-1',
      onConflict: (_) async => fail('no conflict'),
      onCommons: (_) async => null,
    );
    expect(result, isA<StartSessionCancelled>());
    expect(await sessions.inProgress(), isNull);
  });

  test('included commons are copied into the new session', () async {
    final plan = _plan(commons: true);
    final result = await start.run(
      plan: plan,
      planDayId: 'day-1',
      onConflict: (_) async => fail('no conflict'),
      onCommons: (sections) async {
        expect(sections.single.sectionId, 'sec-abs');
        return ['sec-abs'];
      },
    );
    final session = (result as StartSessionOpened).session;
    expect(
      session.exerciseLogs.map((log) => log.exerciseTitle),
      ['squat', 'plank'],
    );
    expect(session.includedCommonSectionIds, ['sec-abs']);
  });

  test('empty day with commons off is empty, not a session', () async {
    final plan = _emptyDayWithCommons();
    final result = await start.run(
      plan: plan,
      planDayId: 'day-1',
      onConflict: (_) async => fail('no conflict'),
      onCommons: (_) async => const <String>[],
    );
    expect(result, isA<StartSessionEmpty>());
    expect(await sessions.inProgress(), isNull);
  });

  test('empty day starts when a common section is turned on', () async {
    final plan = _emptyDayWithCommons();
    final result = await start.run(
      plan: plan,
      planDayId: 'day-1',
      onConflict: (_) async => fail('no conflict'),
      onCommons: (_) async => ['sec-abs'],
    );
    final session = (result as StartSessionOpened).session;
    expect(session.exerciseLogs.single.exerciseTitle, 'plank');
    expect(session.exerciseLogs.single.fromCommonSection, isTrue);
  });
}

WorkoutPlan _plan({
  List<String> dayTitles = const ['Day 1'],
  bool commons = false,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    uuid: 'plan-1',
    title: 'plan 1',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      for (var i = 0; i < dayTitles.length; i++)
        PlanDay.create(
          dayId: 'day-${i + 1}',
          title: dayTitles[i],
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-$i',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-$i',
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
    ],
    commonSections: [
      if (commons)
        CommonSection.create(
          sectionId: 'sec-abs',
          title: 'abs',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-abs',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-plank',
                  title: 'plank',
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

WorkoutPlan _emptyDayWithCommons() {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    uuid: 'plan-empty',
    title: 'plan',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [PlanDay.create(dayId: 'day-1', title: 'Empty')],
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
                prescriptionId: 'p-plank',
                title: 'plank',
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
