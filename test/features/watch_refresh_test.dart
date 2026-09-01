import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/features/plans/plan_page.dart';
import 'package:gym_app/features/plans/plans_home_page.dart';

/// Home and plan screens reload from [PlanRepository.watch] / [SessionRepository.watch].
void main() {
  tearDown(Get.reset);

  testWidgets('home drops a plan after watch fires with an empty catalog',
      (tester) async {
    final plans = _WatchablePlans(plan: _plan());
    final sessions = _WatchableSessions();
    addTearDown(() {
      plans.dispose();
      sessions.dispose();
    });
    Get.put<PlanRepository>(plans);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(const GetMaterialApp(home: PlansHomePage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Push'), findsWidgets);
    expect(find.text('Your plans'), findsOneWidget);

    plans.plan = null;
    plans.emit();
    await tester.pump();
    await tester.pump();

    expect(find.text('Push'), findsNothing);
    expect(
      find.text(
        'No plans yet. Start with a beginner template, import one, or create your first.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('home drops the continue banner after the live session watch',
      (tester) async {
    final plans = _WatchablePlans(plan: _plan());
    final sessions = _WatchableSessions(live: _liveSession());
    addTearDown(() {
      plans.dispose();
      sessions.dispose();
    });
    Get.put<PlanRepository>(plans);
    Get.put<SessionRepository>(sessions);

    await tester.pumpWidget(const GetMaterialApp(home: PlansHomePage()));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('continue-banner')), findsOneWidget);
    expect(find.text('Day 1'), findsWidgets);

    sessions.live = null;
    sessions.emit();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('continue-banner')), findsNothing);
    expect(find.text('Push'), findsWidgets);
  });

  testWidgets('plan page shows gone after watch when the row is missing',
      (tester) async {
    final plans = _WatchablePlans(plan: _plan());
    addTearDown(plans.dispose);
    Get.put<PlanRepository>(plans);

    await tester.pumpWidget(const GetMaterialApp(home: PlanPage(planId: 'plan-uuid')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Day 1'), findsOneWidget);

    plans.plan = null;
    plans.emit();
    await tester.pump();
    await tester.pump();

    expect(find.text('This plan is no longer here.'), findsOneWidget);
    expect(find.text('Day 1'), findsNothing);
    expect(find.text('Try again'), findsNothing);
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
  )..id = 1;
}

class _WatchablePlans implements PlanRepository {
  _WatchablePlans({this.plan});

  WorkoutPlan? plan;
  final _watch = StreamController<void>.broadcast();

  void emit() => _watch.add(null);

  void dispose() => _watch.close();

  @override
  Future<List<WorkoutPlan>> all() async => plan == null ? const [] : [plan!];

  @override
  Future<WorkoutPlan?> byId(int id) async =>
      plan != null && plan!.id == id ? plan : null;

  @override
  Future<WorkoutPlan?> byUuid(String uuid) async =>
      plan != null && plan!.uuid == uuid ? plan : null;

  @override
  Future<int> count() async => plan == null ? 0 : 1;

  @override
  Future<bool> delete(int id) async {
    if (plan == null || plan!.id != id) return false;
    plan = null;
    emit();
    return true;
  }

  @override
  Future<int> putSynced(WorkoutPlan plan) async => plan.id;

  @override
  Future<int> save(WorkoutPlan plan) async => plan.id;

  @override
  Future<List<WorkoutPlan>> unsynced() async => const [];

  @override
  Stream<void> watch({bool fireImmediately = false}) => _watch.stream;
}

class _WatchableSessions implements SessionRepository {
  _WatchableSessions({this.live});

  WorkoutSession? live;
  final _watch = StreamController<void>.broadcast();

  void emit() => _watch.add(null);

  void dispose() => _watch.close();

  @override
  Future<WorkoutSession?> byId(int id) async =>
      live != null && live!.id == id ? live : null;

  @override
  Future<WorkoutSession?> byUuid(String uuid) async =>
      live != null && live!.uuid == uuid ? live : null;

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) async =>
      const [];

  @override
  Future<bool> delete(int id) async => false;

  @override
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) async => const [];

  @override
  Future<List<WorkoutSession>> forMonth(DateTime month) async => const [];

  @override
  Future<WorkoutSession?> inProgress() async => live;

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
