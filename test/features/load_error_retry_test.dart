import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/features/plans/day_editor_page.dart';
import 'package:gym_app/features/plans/day_preview_page.dart';
import 'package:gym_app/features/plans/plan_page.dart';
import 'package:gym_app/features/plans/plans_home_page.dart';
import 'package:gym_app/features/progress/month_tab.dart';
import 'package:gym_app/features/progress/session_log_page.dart';
import 'package:gym_app/features/workout/live_workout_page.dart';

/// Load-error + Try again, using repository fakes (the PR 18 interfaces).
void main() {
  tearDown(Get.reset);

  testWidgets('home shows a load error and retry reads plans again',
      (tester) async {
    final plans = _FlakyPlans(plan: _plan());
    final sessions = _EmptySessions();
    addTearDown(() {
      plans.dispose();
      sessions.dispose();
    });
    Get.put<PlanRepository>(plans);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(const GetMaterialApp(home: PlansHomePage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load plans.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load plans.'), findsNothing);
    expect(find.text('Push'), findsWidgets);
    expect(find.text('Your plans'), findsOneWidget);
  });

  testWidgets('plan page retry reloads after a failed byId', (tester) async {
    final plans = _FlakyPlans(plan: _plan());
    addTearDown(plans.dispose);
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(const GetMaterialApp(home: PlanPage(planId: 1)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this plan.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this plan.'), findsNothing);
    expect(find.text('Day 1'), findsOneWidget);
  });

  testWidgets('day preview retry reloads after a failed byId', (tester) async {
    final plans = _FlakyPlans(plan: _plan());
    addTearDown(plans.dispose);
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: DayPreviewPage(planId: 1, dayId: 'day-1'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this day.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this day.'), findsNothing);
    expect(find.text('squat'), findsOneWidget);
  });

  testWidgets('month tab retry reloads after a failed forMonth', (tester) async {
    final sessions = _EmptySessions()..failForMonth = 1;
    addTearDown(sessions.dispose);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: MonthTab(now: DateTime.utc(2026, 8, 15))),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this month.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this month.'), findsNothing);
    expect(find.text('No workouts this month.'), findsOneWidget);
  });

  testWidgets('day editor retry reloads after a failed byId', (tester) async {
    final plans = _FlakyPlans(plan: _plan());
    addTearDown(plans.dispose);
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: DayEditorPage(planId: 1, dayId: 'day-1'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this day.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this day.'), findsNothing);
    expect(find.text('3 × 10 squat'), findsOneWidget);
  });

  testWidgets('day editor retry reloads a common section after a failed byId',
      (tester) async {
    final plans = _FlakyPlans(plan: _plan());
    addTearDown(plans.dispose);
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: DayEditorPage(planId: 1, sectionId: 'sec-abs'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this section.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this section.'), findsNothing);
    expect(find.text('1 × 30s plank'), findsOneWidget);
  });

  testWidgets('day editor shows gone when the day is missing from a loaded plan',
      (tester) async {
    final plans = _FlakyPlans(plan: _plan())..remainingFailures = 0;
    addTearDown(plans.dispose);
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: DayEditorPage(planId: 1, dayId: 'missing-day'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('This day is no longer here.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('day log retry reloads after a failed forCalendarDay',
      (tester) async {
    final sessions = _EmptySessions(daySessions: [_session()])
      ..failForCalendarDay = 1;
    addTearDown(sessions.dispose);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(
      GetMaterialApp(
        home: DayLogPage(day: DateTime.utc(2026, 8, 15)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this day.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this day.'), findsNothing);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.textContaining('Completed'), findsOneWidget);
  });

  testWidgets('session log retry reloads after a failed byId', (tester) async {
    final sessions = _EmptySessions(session: _session())..failById = 1;
    addTearDown(sessions.dispose);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(
      const GetMaterialApp(home: SessionLogPage(sessionId: 1)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this session.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load this session.'), findsNothing);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('squat'), findsOneWidget);
    expect(find.text('★4'), findsOneWidget);
  });

  testWidgets('session log treats a missing row as gone, not a load error',
      (tester) async {
    final sessions = _EmptySessions();
    addTearDown(sessions.dispose);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(
      const GetMaterialApp(home: SessionLogPage(sessionId: 99)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('This session is gone.'), findsOneWidget);
    expect(find.text('Could not load this session.'), findsNothing);
  });

  testWidgets('live workout retry reloads after a failed byId', (tester) async {
    final sessions = _EmptySessions(session: _liveSession())..failById = 1;
    addTearDown(sessions.dispose);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(
      const GetMaterialApp(home: LiveWorkoutPage(sessionId: 1)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not open this workout.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not open this workout.'), findsNothing);
    expect(find.text('Day 1'), findsWidgets);
    expect(find.text('squat'), findsWidgets);
  });
}

WorkoutPlan _plan() {
  return WorkoutPlan.create(
    uuid: 'plan-uuid',
    title: 'Push',
    source: PlanSource.created,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'Day 1',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-1',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-1',
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
  )..id = 1;
}

WorkoutSession _session() {
  return WorkoutSession.create(
    uuid: 'sess-uuid',
    planId: 'plan-uuid',
    planDayId: 'day-1',
    planTitleSnapshot: 'Push',
    dayTitleSnapshot: 'Day 1',
    startedAt: DateTime.utc(2026, 8, 15, 10),
    updatedAt: DateTime.utc(2026, 8, 15, 11),
    status: SessionStatus.completed,
    exerciseLogs: [
      ExerciseLog.create(
        prescriptionId: 'p-1',
        blockId: 'block-1',
        blockKind: BlockKind.single,
        fromCommonSection: false,
        exerciseTitle: 'squat',
        exerciseTitleKey: 'squat',
        prescribedSets: 3,
        prescribedReps: 10,
        difficulty: 4,
        sets: [
          SetLog.create(
            setIndex: 1,
            completedAt: DateTime.utc(2026, 8, 15, 10, 20),
            reps: 10,
            weightKg: 40,
          ),
        ],
      ),
    ],
  )..id = 1;
}

WorkoutSession _liveSession() {
  return WorkoutSession.create(
    uuid: 'live-uuid',
    planId: 'plan-uuid',
    planDayId: 'day-1',
    planTitleSnapshot: 'Push',
    dayTitleSnapshot: 'Day 1',
    startedAt: DateTime.utc(2026, 8, 15, 10),
    updatedAt: DateTime.utc(2026, 8, 15, 10),
    status: SessionStatus.inProgress,
    exerciseLogs: [
      ExerciseLog.create(
        prescriptionId: 'p-1',
        blockId: 'block-1',
        blockKind: BlockKind.single,
        fromCommonSection: false,
        exerciseTitle: 'squat',
        exerciseTitleKey: 'squat',
        prescribedSets: 3,
        prescribedReps: 10,
      ),
    ],
  )..id = 1;
}

class _FlakyPlans implements PlanRepository {
  _FlakyPlans({required this.plan});

  final WorkoutPlan plan;
  var remainingFailures = 1;
  final _watch = StreamController<void>.broadcast();

  void dispose() => _watch.close();

  T _read<T>(T value) {
    if (remainingFailures > 0) {
      remainingFailures--;
      throw StateError('disk');
    }
    return value;
  }

  @override
  Future<List<WorkoutPlan>> all() async => _read([plan]);

  @override
  Future<WorkoutPlan?> byId(int id) async => _read(plan);

  @override
  Future<WorkoutPlan?> byUuid(String uuid) async => _read(plan);

  @override
  Future<int> count() async => _read(1);

  @override
  Future<bool> delete(int id) async => false;

  @override
  Future<int> putSynced(WorkoutPlan plan) async => plan.id;

  @override
  Future<int> save(WorkoutPlan plan) async => plan.id;

  @override
  Future<List<WorkoutPlan>> unsynced() async => const [];

  @override
  Stream<void> watch({bool fireImmediately = false}) => _watch.stream;
}

class _EmptySessions implements SessionRepository {
  _EmptySessions({this.session, this.daySessions = const []});

  final WorkoutSession? session;
  final List<WorkoutSession> daySessions;
  var failForMonth = 0;
  var failForCalendarDay = 0;
  var failById = 0;
  final _watch = StreamController<void>.broadcast();

  void dispose() => _watch.close();

  @override
  Future<WorkoutSession?> byId(int id) async {
    if (failById > 0) {
      failById--;
      throw StateError('disk');
    }
    if (session == null || session!.id != id) return null;
    return session;
  }

  @override
  Future<WorkoutSession?> byUuid(String uuid) async => null;

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) async =>
      const [];

  @override
  Future<bool> delete(int id) async => false;

  @override
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) async {
    if (failForCalendarDay > 0) {
      failForCalendarDay--;
      throw StateError('disk');
    }
    return daySessions;
  }

  @override
  Future<List<WorkoutSession>> forMonth(DateTime month) async {
    if (failForMonth > 0) {
      failForMonth--;
      throw StateError('disk');
    }
    return const [];
  }

  @override
  Future<WorkoutSession?> inProgress() async => null;

  @override
  Future<WorkoutSession?> lastCompleted({String? planId}) async => null;

  @override
  Future<int> putSynced(WorkoutSession session) async => session.id;

  @override
  Future<int> save(WorkoutSession session) async => session.id;

  @override
  Future<List<WorkoutSession>> unsynced() async => const [];

  @override
  Stream<void> watch({bool fireImmediately = false}) => _watch.stream;
}
