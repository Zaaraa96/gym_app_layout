import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_lifecycle.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/data/starter_plans.dart';
import 'package:gym_app/features/workout/live_workout_page.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_live_');
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

  Future<T> db<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  Future<({PlanRepository plans, SessionRepository sessions})> bootstrap(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    instanceSeq += 1;
    final service = await db(
      tester,
      () =>
          IsarService.init(directory: tempDir!.path, name: 'live$instanceSeq'),
    );
    Get.put<IsarService>(service, permanent: true);
    return (plans: putPlans(service.isar), sessions: putSessions(service.isar));
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  test('formatSignedClock shows overtime with a plus', () {
    expect(formatSignedClock(45), '0:45');
    expect(formatSignedClock(75), '1:15');
    expect(formatSignedClock(-5), '+0:05');
  });

  testWidgets('home suggests today and logging a set advances the workout', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_simplePlan()));

    await launch(tester, AppRoutes.home);

    expect(find.byKey(const Key('today-card')), findsOneWidget);
    expect(find.text('Today: Day 1 — Squat'), findsOneWidget);
    expect(
      find.text('Start with Bodyweight squat, then log what you did.'),
      findsOneWidget,
    );

    await tester.tap(find.text("Start today's workout"));
    await tester.pump();
    await settle(tester);

    expect(find.text('Log what you did on this set.'), findsOneWidget);
    expect(find.text('Bodyweight squat  ·  set 1 of 2'), findsOneWidget);
    expect(find.text('10'), findsWidgets);

    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Bodyweight squat  ·  set 2 of 2'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await settle(tester);

    expect(find.byKey(const Key('continue-banner')), findsOneWidget);
    await tester.tap(find.text('Continue workout'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Bodyweight squat  ·  set 2 of 2'), findsOneWidget);
  });

  testWidgets('live page logs the prefilled reps and then asks for a rating', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);

    expect(find.text('How hard was that? 1 easy · 5 hard'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rate-3')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Workout complete'), findsOneWidget);
    final stored = await db(tester, () => repos.sessions.byId(session.id));
    expect(stored!.status, SessionStatus.completed);
    expect(stored.exerciseLogs.single.sets, hasLength(2));
    expect(stored.exerciseLogs.single.sets.first.reps, 10);
    expect(stored.exerciseLogs.single.difficulty, 3);
  });

  testWidgets('End can finish a partial session from the live page', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);

    final end = find.byKey(const Key('end-workout'));
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pump();
    await settle(tester);

    final finish = find.byKey(const Key('finish-workout'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pump();
    await settle(tester);

    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Nice work. What you logged is saved.'), findsOneWidget);
    expect(find.byKey(const Key('end-workout')), findsNothing);
    final stored = await db(tester, () => repos.sessions.byId(session.id));
    expect(stored!.status, SessionStatus.completed);
    expect(stored.exerciseLogs.single.sets, hasLength(1));
    expect(stored.endedAt, isNotNull);
  });

  testWidgets('home today card uses a stored beginner plan', (tester) async {
    final repos = await bootstrap(tester);
    await db(
      tester,
      () => installStarterPlan(
        starterFullBody,
        plans: repos.plans,
        loadAsset: (path) => File(path).readAsString(),
      ),
    );

    await launch(tester, AppRoutes.home);

    expect(find.byKey(const Key('today-card')), findsOneWidget);
    expect(find.text('Today: Day 1 — Squat and push'), findsOneWidget);
    expect(find.text('Beginner full body'), findsOneWidget);
    expect(
      find.text('Start with Bodyweight squat, then log what you did.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'starting today again while that day is live resumes without a conflict',
    (tester) async {
      final repos = await bootstrap(tester);
      await db(tester, () => repos.plans.save(_simplePlan()));

      await launch(tester, AppRoutes.home);
      await tester.tap(find.text("Start today's workout"));
      await tester.pump();
      await settle(tester);
      expect(find.text('Bodyweight squat  ·  set 1 of 2'), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      await settle(tester);

      await tester.tap(find.text("Start today's workout"));
      await tester.pump();
      await settle(tester);

      expect(find.text('A workout is already in progress'), findsNothing);
      expect(find.text('Bodyweight squat  ·  set 1 of 2'), findsOneWidget);
      expect(await db(tester, () => repos.sessions.inProgress()), isNotNull);
    },
  );

  testWidgets('End then Finish keeps a partial session as completed', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_simplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text("Start today's workout"));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);
    await settle(tester);

    final end = find.byKey(const Key('end-workout'));
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pump();
    await settle(tester);
    final finish = find.byKey(const Key('finish-workout'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pump();
    await settle(tester);

    expect(find.text('Workout complete'), findsOneWidget);
    final stored = await db(tester, () => repos.sessions.inProgress());
    expect(stored, isNull);
    final completed = await db(tester, () => repos.sessions.lastCompleted());
    expect(completed!.status, SessionStatus.completed);
    expect(completed.exerciseLogs.single.sets, hasLength(1));
    expect(completed.exerciseLogs.single.difficulty, isNull);
  });

  testWidgets('End then Discard abandons the session and returns home', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_simplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text("Start today's workout"));
    await tester.pump();
    await settle(tester);
    await settle(tester);

    final end = find.byKey(const Key('end-workout'));
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pump();
    await settle(tester);
    final discard = find.byKey(const Key('discard-workout'));
    await tester.ensureVisible(discard);
    await tester.tap(discard);
    await tester.pump();
    await settle(tester);

    expect(find.byKey(const Key('continue-banner')), findsNothing);
    expect(find.byKey(const Key('today-card')), findsOneWidget);
    expect(await db(tester, () => repos.sessions.inProgress()), isNull);
    expect(await db(tester, () => repos.sessions.lastCompleted()), isNull);
  });

  testWidgets('End then Keep going leaves the live session in progress', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_simplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text("Start today's workout"));
    await tester.pump();
    await settle(tester);
    await settle(tester);

    final end = find.byKey(const Key('end-workout'));
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Keep going'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Workout complete'), findsNothing);
    expect(find.text('Workout discarded'), findsNothing);
    expect(find.text('Log set'), findsOneWidget);
    expect(find.byKey(const Key('end-workout')), findsOneWidget);
    final live = await db(tester, () => repos.sessions.inProgress());
    expect(live, isNotNull);
    expect(live!.status, SessionStatus.inProgress);
    expect(live.endedAt, isNull);
  });

  testWidgets(
    'an empty live session shows nothing to log instead of a logger',
    (tester) async {
      final repos = await bootstrap(tester);
      final session = WorkoutSession.create(
        planId: 'plan-uuid',
        planDayId: 'day-1',
        planTitleSnapshot: 'Simple',
        dayTitleSnapshot: 'Empty live',
        startedAt: DateTime.utc(2026, 8, 28, 12),
        status: SessionStatus.inProgress,
      );
      await db(tester, () => repos.sessions.save(session));

      await tester.pumpWidget(
        GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
      );
      await settle(tester);

      expect(
        find.text('Nothing to log. End this workout or go back.'),
        findsOneWidget,
      );
      expect(find.text('Log set'), findsNothing);
      expect(find.text('Log time'), findsNothing);
      expect(find.byKey(const Key('end-workout')), findsOneWidget);
    },
  );

  testWidgets(
    'starting the duration timer then logging immediately stores elapsed 0',
    (tester) async {
      final repos = await bootstrap(tester);
      final plan = _durationPlan();
      await db(tester, () => repos.plans.save(plan));
      final session = await db(
        tester,
        () => SessionLifecycle(repos.sessions).start(
          plan: plan,
          planDayId: 'day-1',
          startedAt: DateTime.utc(2026, 8, 28, 12),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
      );
      await settle(tester);

      expect(find.text('0:30'), findsOneWidget);
      expect(find.text('Start timer'), findsOneWidget);
      expect(find.text('Log time'), findsOneWidget);
      expect(find.text('Log set'), findsNothing);

      await tester.tap(find.text('Start timer'));
      await tester.pump();
      expect(find.text('Running…'), findsOneWidget);
      expect(find.text('Start timer'), findsNothing);

      await tester.tap(find.text('Log time'));
      await tester.pump();
      await settle(tester);

      final stored = await db(tester, () => repos.sessions.byId(session.id));
      expect(stored!.status, SessionStatus.inProgress);
      expect(stored.exerciseLogs.single.sets, hasLength(1));
      expect(stored.exerciseLogs.single.sets.single.durationSeconds, 0);
    },
  );

  testWidgets(
    'duration Log time without starting the timer stores the prescription',
    (tester) async {
      final repos = await bootstrap(tester);
      final plan = _durationPlan();
      await db(tester, () => repos.plans.save(plan));
      final session = await db(
        tester,
        () => SessionLifecycle(repos.sessions).start(
          plan: plan,
          planDayId: 'day-1',
          startedAt: DateTime.utc(2026, 8, 28, 12),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
      );
      await settle(tester);

      await tester.tap(find.text('Log time'));
      await tester.pump();
      await settle(tester);

      final stored = await db(tester, () => repos.sessions.byId(session.id));
      expect(stored!.exerciseLogs.single.sets.single.durationSeconds, 30);
      expect(stored.status, SessionStatus.inProgress);
      expect(find.text('How hard was that? 1 easy · 5 hard'), findsOneWidget);
    },
  );

  testWidgets(
    'finishing today’s workout offers the next day from the home card',
    (tester) async {
      final repos = await bootstrap(tester);
      await db(tester, () => repos.plans.save(_twoDayPlan()));

      await launch(tester, AppRoutes.home);
      expect(find.text("Start today's workout"), findsOneWidget);
      expect(find.text('Today: Day 1 — Squat'), findsOneWidget);

      await tester.tap(find.text("Start today's workout"));
      await tester.pump();
      await settle(tester);
      await settle(tester);

      final end = find.byKey(const Key('end-workout'));
      await tester.ensureVisible(end);
      await tester.tap(end);
      await tester.pump();
      await settle(tester);
      final finish = find.byKey(const Key('finish-workout'));
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.pump();
      await settle(tester);

      expect(find.text('Workout complete'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pump();
      await settle(tester);

      expect(find.byKey(const Key('continue-banner')), findsNothing);
      expect(find.byKey(const Key('today-card')), findsOneWidget);
      expect(find.text('Next up: Day 2 — Push'), findsOneWidget);
      expect(find.text('Start next day'), findsOneWidget);
      expect(find.text("Start today's workout"), findsNothing);
      expect(await db(tester, () => repos.sessions.inProgress()), isNull);
    },
  );

  testWidgets(
    'an empty reps field uses the prescription and stores typed weight',
    (tester) async {
      final repos = await bootstrap(tester);
      final plan = _simplePlan();
      await db(tester, () => repos.plans.save(plan));
      final session = await db(
        tester,
        () => SessionLifecycle(repos.sessions).start(
          plan: plan,
          planDayId: 'day-1',
          startedAt: DateTime.utc(2026, 8, 28, 12),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
      );
      await settle(tester);

      await tester.enterText(find.byKey(const Key('weight-field')), '40.5');
      await tester.enterText(find.byKey(const Key('reps-field')), '');
      await tester.tap(find.text('Log set'));
      await tester.pump();
      await settle(tester);

      final stored = await db(tester, () => repos.sessions.byId(session.id));
      expect(stored!.status, SessionStatus.inProgress);
      expect(stored.exerciseLogs.single.sets, hasLength(1));
      expect(stored.exerciseLogs.single.sets.single.reps, 10);
      expect(stored.exerciseLogs.single.sets.single.weightKg, 40.5);
      expect(find.text('Bodyweight squat  ·  set 2 of 2'), findsOneWidget);
    },
  );

  testWidgets('zero reps are rejected before a set is written', (tester) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    await tester.enterText(find.byKey(const Key('reps-field')), '0');
    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Reps are required.'), findsOneWidget);
    final stored = await db(tester, () => repos.sessions.byId(session.id));
    expect(stored!.exerciseLogs.single.sets, isEmpty);
    expect(stored.status, SessionStatus.inProgress);
  });

  testWidgets('a non-numeric weight is rejected before a set is written', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    await tester.enterText(find.byKey(const Key('weight-field')), 'heavy');
    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);

    expect(
      find.text('Weight must be a number, or leave it empty.'),
      findsOneWidget,
    );
    final stored = await db(tester, () => repos.sessions.byId(session.id));
    expect(stored!.exerciseLogs.single.sets, isEmpty);
    expect(stored.status, SessionStatus.inProgress);
  });

  testWidgets('Start rest and Reset rest toggle the rest controls', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    expect(find.text('Rest  0:00'), findsOneWidget);
    expect(find.text('Start rest'), findsOneWidget);

    await tester.ensureVisible(find.text('Start rest'));
    await tester.tap(find.text('Start rest'));
    await tester.pump();

    expect(find.text('Resting…'), findsOneWidget);
    expect(find.text('Start rest'), findsNothing);

    await tester.tap(find.text('Reset rest'));
    await tester.pump();

    expect(find.text('Start rest'), findsOneWidget);
    expect(find.text('Resting…'), findsNothing);
    expect(find.text('Rest  0:00'), findsOneWidget);
    expect(await db(tester, () => repos.sessions.byId(session.id)), isNotNull);
    expect(
      (await db(tester, () => repos.sessions.byId(session.id)))!.status,
      SessionStatus.inProgress,
    );
  });

  testWidgets('Keep going leaves the live session open', (tester) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('end-workout')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Keep going'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Log set'), findsOneWidget);
    final stillLive = await db(tester, () => repos.sessions.byId(session.id));
    expect(stillLive!.status, SessionStatus.inProgress);
  });

  testWidgets('a missing session shows a load error that retry keeps showing', (
    tester,
  ) async {
    await bootstrap(tester);

    await tester.pumpWidget(
      const GetMaterialApp(home: LiveWorkoutPage(sessionId: 999999)),
    );
    await settle(tester);

    expect(find.text('Could not open this workout.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await settle(tester);
    expect(find.text('Could not open this workout.'), findsOneWidget);
  });

  testWidgets('Log time stores the prescribed hold when the timer never ran', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final plan = _durationPlan();
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    expect(
      find.text('Start the hold, then log the time you actually did.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Log time'));
    await tester.pump();
    await settle(tester);

    expect(find.text('How hard was that? 1 easy · 5 hard'), findsOneWidget);
    final held = await db(tester, () => repos.sessions.byId(session.id));
    expect(held!.exerciseLogs.single.sets.single.durationSeconds, 30);
  });

  testWidgets('an empty session asks to end instead of showing a logger', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final now = DateTime.utc(2026, 8, 28, 12);
    final plan = WorkoutPlan.create(
      title: 'Empty',
      source: PlanSource.created,
      createdAt: now,
      updatedAt: now,
      days: [PlanDay.create(dayId: 'day-1', title: 'Empty day')],
    );
    await db(tester, () => repos.plans.save(plan));
    final session = await db(
      tester,
      () => SessionLifecycle(
        repos.sessions,
      ).start(plan: plan, planDayId: 'day-1', startedAt: now),
    );

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
    );
    await settle(tester);

    expect(
      find.text('Nothing to log. End this workout or go back.'),
      findsOneWidget,
    );
    expect(find.text('Log set'), findsNothing);
  });

  testWidgets(
    'empty reps use the prescription, empty weight is bodyweight, and extras show',
    (tester) async {
      final repos = await bootstrap(tester);
      final plan = _simplePlan();
      await db(tester, () => repos.plans.save(plan));
      final session = await db(
        tester,
        () => SessionLifecycle(repos.sessions).start(
          plan: plan,
          planDayId: 'day-1',
          startedAt: DateTime.utc(2026, 8, 28, 12),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(home: LiveWorkoutPage(sessionId: session.id)),
      );
      await settle(tester);

      await tester.enterText(find.byKey(const Key('reps-field')), '');
      await tester.tap(find.text('Log set'));
      await tester.pump();
      await settle(tester);

      expect(find.text('Bodyweight squat  ·  set 2 of 2'), findsOneWidget);
      final afterFirst = await db(
        tester,
        () => repos.sessions.byId(session.id),
      );
      expect(afterFirst!.exerciseLogs.single.sets, hasLength(1));
      expect(afterFirst.exerciseLogs.single.sets.single.reps, 10);
      expect(afterFirst.exerciseLogs.single.sets.single.weightKg, isNull);

      await tester.enterText(find.byKey(const Key('weight-field')), '22.5');
      await tester.tap(find.text('Log set'));
      await tester.pump();
      await settle(tester);

      expect(find.text('Bodyweight squat  ·  set 3  ·  extra'), findsOneWidget);
      expect(find.text('How hard was that? 1 easy · 5 hard'), findsOneWidget);
      final afterSecond = await db(
        tester,
        () => repos.sessions.byId(session.id),
      );
      expect(afterSecond!.exerciseLogs.single.sets, hasLength(2));
      expect(afterSecond.exerciseLogs.single.sets.last.reps, 10);
      expect(afterSecond.exerciseLogs.single.sets.last.weightKg, 22.5);
      expect(afterSecond.status, SessionStatus.inProgress);
    },
  );

  testWidgets('reopening a live session prefills the last logged weight', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_simplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text("Start today's workout"));
    await tester.pump();
    await settle(tester);

    await tester.enterText(find.byKey(const Key('weight-field')), '40');
    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);

    await tester.pageBack();
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Continue workout'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Bodyweight squat  ·  set 2 of 2'), findsOneWidget);
    expect(_weightText(tester), '40');
  });

  testWidgets('Done after a completed workout returns home', (tester) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_simplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text("Start today's workout"));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Log set'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('rate-3')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Workout complete'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    await settle(tester);

    expect(find.byKey(const Key('today-card')), findsOneWidget);
    expect(find.byKey(const Key('continue-banner')), findsNothing);
    expect(await db(tester, () => repos.sessions.inProgress()), isNull);
    final completed = await db(tester, () => repos.sessions.lastCompleted());
    expect(completed!.status, SessionStatus.completed);
    expect(completed.exerciseLogs.single.difficulty, 3);
  });

  testWidgets('opening a live session prefills the last logged weight', (
    tester,
  ) async {
    final repos = await bootstrap(tester);
    final plan = _simplePlan();
    await db(tester, () => repos.plans.save(plan));
    final fractional = await db(tester, () async {
      final session = await SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      );
      final log = session.exerciseLogs.single;
      log.sets = [
        SetLog.create(
          setIndex: 1,
          completedAt: DateTime.utc(2026, 8, 28, 12, 5),
          reps: 10,
          weightKg: 40.5,
        ),
      ];
      session.exerciseLogs = [log];
      await repos.sessions.save(session);
      return session;
    });

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: fractional.id)),
    );
    await settle(tester);

    expect(_weightText(tester), '40.5');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await db(tester, () async {
      final log = fractional.exerciseLogs.single;
      log.sets = [
        SetLog.create(
          setIndex: 1,
          completedAt: DateTime.utc(2026, 8, 28, 12, 5),
          reps: 10,
          weightKg: 40,
        ),
      ];
      fractional.exerciseLogs = [log];
      await repos.sessions.save(fractional);
    });

    await tester.pumpWidget(
      GetMaterialApp(home: LiveWorkoutPage(sessionId: fractional.id)),
    );
    await settle(tester);

    expect(_weightText(tester), '40');
  });
}

String _weightText(WidgetTester tester) {
  final field = tester.widget<TextFormField>(
    find.descendant(
      of: find.byKey(const Key('weight-field')),
      matching: find.byType(TextFormField),
    ),
  );
  return field.controller!.text;
}

WorkoutPlan _twoDayPlan() {
  final now = DateTime.utc(2026, 8, 28, 12);
  ExerciseBlock single(String id, String title) => ExerciseBlock.create(
        blockId: 'block-$id',
        kind: BlockKind.single,
        exercises: [
          ExercisePrescription.create(
            prescriptionId: 'p-$id',
            title: title,
            prescribedSets: 2,
            prescribedReps: 10,
          ),
        ],
      );
  return WorkoutPlan.create(
    title: 'A/B',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'Day 1 — Squat',
        blocks: [single('squat', 'Bodyweight squat')],
      ),
      PlanDay.create(
        dayId: 'day-2',
        title: 'Day 2 — Push',
        blocks: [single('push', 'push up')],
      ),
    ],
  );
}

WorkoutPlan _durationPlan() {
  final now = DateTime.utc(2026, 8, 28, 12);
  return WorkoutPlan.create(
    title: 'Holds',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'Day 1 — Plank',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-plank',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-plank',
                title: 'Plank',
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

WorkoutPlan _simplePlan() {
  final now = DateTime.utc(2026, 8, 28, 12);
  return WorkoutPlan.create(
    title: 'Simple',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'Day 1 — Squat',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-squat',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-squat',
                title: 'Bodyweight squat',
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
