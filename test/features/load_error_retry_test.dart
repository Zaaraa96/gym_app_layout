import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/features/plans/day_preview_page.dart';
import 'package:gym_app/features/plans/plan_page.dart';
import 'package:gym_app/features/plans/plans_home_page.dart';
import 'package:gym_app/features/progress/month_tab.dart';

/// Retry UI when a repository read fails. Interfaces from the sync split make
/// this possible without a real Isar failure.
void main() {
  tearDown(Get.reset);

  testWidgets('home Try again reloads plans after a failed all()',
      (tester) async {
    final plans = _MemoryPlans(
      items: [_plan()],
      allFails: 1,
    );
    Get.put<PlanRepository>(plans);
    Get.put<SessionRepository>(_MemorySessions());

    await tester.pumpWidget(const GetMaterialApp(home: PlansHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Could not load plans.'), findsOneWidget);
    expect(find.text('Push'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load plans.'), findsNothing);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text("Start today's workout"), findsOneWidget);
  });

  testWidgets('plan Try again reloads after a failed byId()', (tester) async {
    final plans = _MemoryPlans(
      items: [_plan()],
      byIdFails: 1,
    );
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(const GetMaterialApp(home: PlanPage(planId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this plan.'), findsOneWidget);
    expect(find.text('Push'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this plan.'), findsNothing);
    expect(find.text('Push'), findsWidgets);
    expect(find.text('day 1'), findsOneWidget);
  });

  testWidgets('day preview Try again reloads after a failed byId()',
      (tester) async {
    final plans = _MemoryPlans(
      items: [_plan()],
      byIdFails: 1,
    );
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: DayPreviewPage(planId: 1, dayId: 'day-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this day.'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this day.'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('squat'), findsOneWidget);
  });

  testWidgets('month Try again reloads after a failed forMonth()',
      (tester) async {
    final clock = DateTime.utc(2026, 8, 15);
    final sessions = _MemorySessions(
      forMonthFails: 1,
      monthSessions: [_completedSession(startedAt: clock)],
    );
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: MonthTab(now: clock)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this month.'), findsOneWidget);
    expect(find.byKey(const Key('month-calendar')), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load this month.'), findsNothing);
    expect(find.byKey(const Key('month-calendar')), findsOneWidget);
    expect(find.byKey(const Key('month-dot-15')), findsOneWidget);
    expect(find.text('squat'), findsOneWidget);
  });
}

WorkoutPlan _plan() {
  return WorkoutPlan.create(
    uuid: 'plan-uuid',
    title: 'Push',
    source: PlanSource.created,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
    days: [
      PlanDay.create(
        dayId: 'day-1',
        title: 'day 1',
        blocks: [
          ExerciseBlock.create(
            blockId: 'block-1',
            kind: BlockKind.single,
            exercises: [
              ExercisePrescription.create(
                prescriptionId: 'p-squat',
                title: 'squat',
                prescribedSets: 3,
                prescribedReps: 10,
              ),
            ],
          ),
        ],
      ),
    ],
  )..id = 1;
}

WorkoutSession _completedSession({required DateTime startedAt}) {
  return WorkoutSession.create(
    uuid: 'sess-1',
    planId: 'plan-uuid',
    planDayId: 'day-1',
    planTitleSnapshot: 'Push',
    dayTitleSnapshot: 'day 1',
    startedAt: startedAt,
    updatedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    status: SessionStatus.completed,
    exerciseLogs: [
      ExerciseLog.create(
        prescriptionId: 'p-squat',
        blockId: 'block-1',
        blockKind: BlockKind.single,
        fromCommonSection: false,
        exerciseTitle: 'squat',
        exerciseTitleKey: 'squat',
        prescribedSets: 3,
        prescribedReps: 10,
        sets: [
          SetLog.create(
            setIndex: 1,
            completedAt: startedAt,
            reps: 10,
            weightKg: 40,
          ),
        ],
      ),
    ],
  )..id = 3;
}

class _MemoryPlans implements PlanRepository {
  _MemoryPlans({
    this.items = const [],
    this.allFails = 0,
    this.byIdFails = 0,
  });

  final List<WorkoutPlan> items;
  int allFails;
  int byIdFails;

  @override
  Future<List<WorkoutPlan>> all() async {
    if (allFails > 0) {
      allFails -= 1;
      throw StateError('plans down');
    }
    return items;
  }

  @override
  Future<WorkoutPlan?> byId(int id) async {
    if (byIdFails > 0) {
      byIdFails -= 1;
      throw StateError('plan down');
    }
    for (final plan in items) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Future<WorkoutPlan?> byUuid(String uuid) async {
    for (final plan in items) {
      if (plan.uuid == uuid) return plan;
    }
    return null;
  }

  @override
  Future<int> count() async => items.length;

  @override
  Future<bool> delete(int id) async => false;

  @override
  Future<int> putSynced(WorkoutPlan plan) async => plan.id;

  @override
  Future<int> save(WorkoutPlan plan) async => plan.id;

  @override
  Future<List<WorkoutPlan>> unsynced() async => const [];

  @override
  Stream<void> watch({bool fireImmediately = false}) => const Stream.empty();
}

class _MemorySessions implements SessionRepository {
  _MemorySessions({
    this.monthSessions = const [],
    this.forMonthFails = 0,
  });

  final List<WorkoutSession> monthSessions;
  int forMonthFails;

  @override
  Future<WorkoutSession?> byId(int id) async => null;

  @override
  Future<WorkoutSession?> byUuid(String uuid) async => null;

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) async =>
      const [];

  @override
  Future<bool> delete(int id) async => false;

  @override
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) async => const [];

  @override
  Future<List<WorkoutSession>> forMonth(DateTime month) async {
    if (forMonthFails > 0) {
      forMonthFails -= 1;
      throw StateError('month down');
    }
    return monthSessions;
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
  Stream<void> watch({bool fireImmediately = false}) => const Stream.empty();
}
