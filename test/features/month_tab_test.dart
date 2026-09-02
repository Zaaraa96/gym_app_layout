import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_lifecycle.dart';
import 'package:gym_app/domain/session_repository.dart';
import 'package:gym_app/features/progress/progress_format.dart';
import 'package:gym_app/features/progress/session_log_page.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_month_');
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
        name: 'month$instanceSeq',
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

  Future<void> openMonth(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);
  }

  DateTime thisMonth({int day = 15, int hour = 10}) {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, day, hour);
  }

  DateTime lastMonth({int day = 15, int hour = 10}) {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month - 1, day, hour);
  }

  testWidgets('an empty month still shows the calendar', (tester) async {
    final repos = await bootstrap(tester);
    await db(tester, () => repos.plans.save(_plan()));

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(
      find.text('The month calendar arrives with session logging.'),
      findsNothing,
    );
    expect(find.text(formatMonthTitle(DateTime.now().toUtc())), findsOneWidget);
    expect(find.byKey(const Key('month-calendar')), findsOneWidget);
    expect(find.text('No workouts this month.'), findsOneWidget);
  });

  testWidgets('completed sessions get a dot, a trend row, and a session log',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));
    await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        startedAt: thisMonth(day: 15),
        weight: 40,
        reps: 12,
        difficulty: 4,
      ),
    );
    await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        startedAt: thisMonth(day: 20, hour: 9),
        weight: 45,
        reps: 12,
        difficulty: 3,
      ),
    );

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.text('No workouts this month.'), findsNothing);
    expect(find.byKey(const Key('month-dot-15')), findsOneWidget);
    expect(find.byKey(const Key('month-dot-20')), findsOneWidget);
    expect(find.text('kang squat'), findsOneWidget);
    expect(find.text('45 kg  ·  +5 kg  ·  felt easier'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-day-15')));
    await tester.pump();
    await settle(tester);

    expect(find.text('day 1'), findsWidgets);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Set 1  40 kg × 12'), findsOneWidget);
    expect(find.text('★4'), findsOneWidget);
  });

  testWidgets('several sessions on one day list oldest first', (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan(dayCount: 2);
    await db(tester, () => repos.plans.save(plan));
    final morning = await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        startedAt: thisMonth(day: 15, hour: 7),
        weight: 40,
        reps: 8,
      ),
    );
    final evening = await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        dayId: 'day-2',
        startedAt: thisMonth(day: 15, hour: 18),
        weight: 50,
        reps: 10,
      ),
    );

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    await tester.tap(find.byKey(const Key('month-day-15')));
    await tester.pump();
    await settle(tester);

    expect(find.byKey(const Key('day-log-list')), findsOneWidget);
    final first = tester.getTopLeft(
      find.byKey(Key('day-log-session-${morning.uuid}')),
    );
    final second = tester.getTopLeft(
      find.byKey(Key('day-log-session-${evening.uuid}')),
    );
    expect(first.dy, lessThan(second.dy));

    await tester.tap(find.byKey(Key('day-log-session-${evening.uuid}')));
    await tester.pump();
    await settle(tester);

    expect(find.text('day 2'), findsWidgets);
    expect(find.text('Set 1  50 kg × 10'), findsOneWidget);
  });

  testWidgets(
      'an in-progress session still gets a calendar dot and opens as live',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));
    await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: thisMonth(day: 15),
      ),
    );

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.byKey(const Key('month-dot-15')), findsOneWidget);
    expect(find.text('No workouts this month.'), findsNothing);
    expect(find.text('kang squat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-day-15')));
    await tester.pump();
    await settle(tester);

    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('No sets logged'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('month tab picks up a session that lands after the first load',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));

    await launch(tester, AppRoutes.home);
    await openMonth(tester);
    expect(find.text('No workouts this month.'), findsOneWidget);
    expect(find.byKey(const Key('month-dot-15')), findsNothing);

    await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        startedAt: thisMonth(day: 15),
        weight: 40,
        reps: 12,
        difficulty: 3,
      ),
    );
    await settle(tester);

    expect(find.byKey(const Key('month-dot-15')), findsOneWidget);
    expect(find.text('kang squat'), findsOneWidget);
    expect(find.text('No workouts this month.'), findsNothing);
  });

  testWidgets('abandoned sessions do not appear and next month is empty',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));
    await db(tester, () async {
      final session = await SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: thisMonth(day: 12),
      );
      session.status = SessionStatus.abandoned;
      session.endedAt = thisMonth(day: 12, hour: 11);
      await repos.sessions.save(session);
    });

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.byKey(const Key('month-dot-12')), findsNothing);
    expect(find.text('No workouts this month.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-next')));
    await tester.pump();
    await settle(tester);

    final next = DateTime.utc(
      DateTime.now().toUtc().year,
      DateTime.now().toUtc().month + 1,
    );
    expect(find.text(formatMonthTitle(next)), findsOneWidget);
    expect(find.text('No workouts this month.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-prev')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('month-prev')));
    await tester.pump();
    await settle(tester);

    final previous = DateTime.utc(
      DateTime.now().toUtc().year,
      DateTime.now().toUtc().month - 1,
    );
    expect(find.text(formatMonthTitle(previous)), findsOneWidget);
    expect(find.text('No workouts this month.'), findsOneWidget);
  });

  testWidgets('a missing session log shows that it is gone', (tester) async {
    await bootstrap(tester);

    await tester.pumpWidget(
      GetMaterialApp(
        home: SessionLogPage(
          sessionId: 'missing-session',
          ports: Get.find<AppPorts>(),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('This session is gone.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await settle(tester);
    expect(find.text('This session is gone.'), findsOneWidget);
  });

  testWidgets('opening an empty day log lists no workouts', (tester) async {
    await bootstrap(tester);

    await tester.pumpWidget(
      GetMaterialApp(
        home: DayLogPage(
          day: DateTime.utc(2026, 8, 15),
          ports: Get.find<AppPorts>(),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('No workouts this day.'), findsOneWidget);
    expect(find.byKey(const Key('day-log-list')), findsNothing);
  });

  testWidgets('a live session gets a dot and opens as in progress with no sets',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));
    await db(
      tester,
      () => SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: thisMonth(day: 8, hour: 9),
      ),
    );

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.byKey(const Key('month-dot-8')), findsOneWidget);
    expect(find.text('No workouts this month.'), findsNothing);
    expect(find.text('0 reps'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-day-8')));
    await tester.pump();
    await settle(tester);

    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('No sets logged'), findsOneWidget);
    expect(find.text('kang squat'), findsWidgets);
  });

  testWidgets('an empty calendar day lists no workouts', (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));
    await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        startedAt: thisMonth(day: 15),
        weight: 40,
        reps: 12,
      ),
    );

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    await tester.tap(find.byKey(const Key('month-day-1')));
    await tester.pump();
    await settle(tester);

    expect(find.text('No workouts this day.'), findsOneWidget);
    expect(find.byKey(const Key('day-log-list')), findsNothing);
  });

  testWidgets('previous month shows that month’s completed session',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _plan();
    await db(tester, () => repos.plans.save(plan));
    await db(
      tester,
      () => _complete(
        repos.sessions,
        plan: plan,
        startedAt: lastMonth(day: 10),
        weight: 35,
        reps: 8,
      ),
    );

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.text('No workouts this month.'), findsOneWidget);
    expect(find.byKey(const Key('month-dot-10')), findsNothing);

    await tester.tap(find.byKey(const Key('month-prev')));
    await tester.pump();
    await settle(tester);

    final previous = DateTime.utc(
      DateTime.now().toUtc().year,
      DateTime.now().toUtc().month - 1,
    );
    expect(find.text(formatMonthTitle(previous)), findsOneWidget);
    expect(find.byKey(const Key('month-dot-10')), findsOneWidget);
    expect(find.text('35 kg'), findsOneWidget);
  });

  testWidgets('a duration session with no sets shows no logged work',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _holdPlan();
    await db(tester, () => repos.plans.save(plan));
    await db(tester, () async {
      final session = await SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: thisMonth(day: 18),
      );
      session.status = SessionStatus.completed;
      session.endedAt = thisMonth(day: 18, hour: 11);
      await repos.sessions.save(session);
    });

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.text('shoot out'), findsOneWidget);
    expect(find.text('No logged sets'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-trend-shoot out')));
    await tester.pump();
    await settle(tester);
    expect(find.text('0/1 sets'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-day-18')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('No sets logged'), findsOneWidget);
  });

  testWidgets('a logged duration hold shows the clock line on the session log',
      (tester) async {
    final repos = await bootstrap(tester);
    final plan = _holdPlan();
    await db(tester, () => repos.plans.save(plan));
    await db(tester, () async {
      final session = await SessionLifecycle(repos.sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: thisMonth(day: 18),
      );
      final log = session.exerciseLogs.single;
      log.sets = [
        SetLog.create(
          setIndex: 1,
          completedAt: thisMonth(day: 18, hour: 10),
          durationSeconds: 35,
        ),
      ];
      log.difficulty = 2;
      log.completedAt = thisMonth(day: 18, hour: 10);
      session.exerciseLogs = [log];
      session.status = SessionStatus.completed;
      session.endedAt = thisMonth(day: 18, hour: 11);
      await repos.sessions.save(session);
    });

    await launch(tester, AppRoutes.home);
    await openMonth(tester);

    expect(find.text('shoot out'), findsOneWidget);
    expect(find.text('0:35'), findsOneWidget);

    await tester.tap(find.byKey(const Key('month-day-18')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Set 1  0:35'), findsOneWidget);
    expect(find.text('★2'), findsOneWidget);
    expect(find.text('No sets logged'), findsNothing);
  });
}

WorkoutPlan _holdPlan() {
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
            blockId: 'block-hold',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-hold',
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

WorkoutPlan _plan({int dayCount = 1}) {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'plan 1',
    source: PlanSource.imported,
    createdAt: now,
    updatedAt: now,
    days: List.generate(
      dayCount,
      (index) => PlanDay.create(
        dayId: 'day-${index + 1}',
        title: 'day ${index + 1}',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-${index + 1}',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-${index + 1}',
                title: 'kang squat',
                prescribedSets: 3,
                prescribedReps: 12,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<WorkoutSession> _complete(
  SessionRepository sessions, {
  required WorkoutPlan plan,
  required DateTime startedAt,
  required double weight,
  required int reps,
  String dayId = 'day-1',
  int? difficulty,
}) async {
  final session = await SessionLifecycle(sessions).start(
    plan: plan,
    planDayId: dayId,
    startedAt: startedAt,
  );
  final log = session.exerciseLogs.first;
  log.sets = [
    SetLog.create(
      setIndex: 1,
      completedAt: startedAt,
      reps: reps,
      weightKg: weight,
    ),
  ];
  log.difficulty = difficulty;
  log.completedAt = difficulty == null ? null : startedAt;
  session.exerciseLogs = [log];
  session.status = SessionStatus.completed;
  session.endedAt = startedAt;
  await sessions.save(session);
  return session;
}
