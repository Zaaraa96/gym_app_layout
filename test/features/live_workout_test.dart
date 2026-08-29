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
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'live$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    return (
      plans: putPlans(service.isar),
      sessions: putSessions(service.isar),
    );
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

  testWidgets('home suggests today and logging a set advances the workout',
      (tester) async {
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

  testWidgets('live page logs the prefilled reps and then asks for a rating',
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
      GetMaterialApp(
        home: LiveWorkoutPage(sessionId: session.id),
      ),
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
