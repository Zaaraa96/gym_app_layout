import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

/// Step 2: stored plans decide the launch route, and both branches of the fork
/// reach the import and create actions.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_fork_');
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

  /// Isar work has to leave the fake-async zone or the host run never sees it
  /// complete.
  Future<T> db<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  /// Opens an empty database on a fresh app tree.
  ///
  /// Unmounting first matters on device: the live binding keeps the previous
  /// case's tree, and a retained [GetMaterialApp] would ignore the new
  /// `initialRoute`. Registering as permanent keeps the stale route left over
  /// from that tree from taking the fresh instances down with it.
  Future<PlanRepository> bootstrap(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    instanceSeq += 1;
    final service = await db(
      tester,
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'fork$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    putSessions(service.isar);
    return putPlans(service.isar);
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  testWidgets('with no stored plans the app opens the welcome fork',
      (tester) async {
    final plans = await bootstrap(tester);

    expect(await db(tester, plans.count), 0);
    expect(await db(tester, () => resolveInitialRoute(plans)),
        AppRoutes.welcome);

    await launch(tester, AppRoutes.welcome);

    expect(find.text('Start with a beginner plan'), findsOneWidget);
    expect(find.text('Import a plan'), findsOneWidget);
    expect(find.text('Create a plan'), findsOneWidget);

    await tester.tap(find.text('Create a plan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.currentRoute, AppRoutes.newPlan);
  });

  testWidgets('the beginner CTA opens the starter picker', (tester) async {
    await bootstrap(tester);
    await launch(tester, AppRoutes.welcome);

    await tester.tap(find.text('Start with a beginner plan'));
    await tester.pump();
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.starters);
    expect(find.text('Beginner full body'), findsOneWidget);
    expect(find.text('Beginner 2-day'), findsOneWidget);
  });

  testWidgets('using a beginner plan writes it and opens home', (tester) async {
    final plans = await bootstrap(tester);
    await launch(tester, AppRoutes.welcome);

    await tester.tap(find.text('Start with a beginner plan'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byKey(const Key('use-starter-beginner-full-body')));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('Beginner full body'), findsOneWidget);
    expect(find.byKey(const Key('today-card')), findsOneWidget);
    expect(find.text('Today: Day 1 — Squat and push'), findsOneWidget);
    expect(await db(tester, plans.count), 1);
    final stored = await db(tester, plans.all);
    expect(stored.single.source, PlanSource.imported);
    expect(stored.single.days, hasLength(3));
  });

  testWidgets('a stored plan sends the app to the plans home', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(_plan('plan 1', dayCount: 3)));

    expect(await db(tester, () => resolveInitialRoute(plans)), AppRoutes.home);

    await launch(tester, AppRoutes.home);

    expect(find.text('Plans'), findsWidgets);
    expect(find.text('plan 1'), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
    expect(find.byKey(const Key('today-card')), findsOneWidget);
    expect(find.text('Today: day 1'), findsOneWidget);
    expect(
      find.text('Start with kang squat, then log what you did.'),
      findsOneWidget,
    );
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Import a plan'), findsNothing);
  });

  testWidgets('the plans list follows Isar writes and the day count singular',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(_plan('only plan', dayCount: 1)));

    await launch(tester, AppRoutes.home);
    expect(find.text('only plan'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);

    await db(tester, () => plans.save(_plan('added later', dayCount: 2)));
    await settle(tester);

    expect(find.text('added later'), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('an empty plans home still offers import and create',
      (tester) async {
    await bootstrap(tester);

    await launch(tester, AppRoutes.home);

    expect(
      find.text(
        'No plans yet. Start with a beginner template, import one, or create your first.',
      ),
      findsOneWidget,
    );
    expect(find.text('Start with a beginner plan'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);

    await tester.tap(find.text('New'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.currentRoute, AppRoutes.newPlan);
  });

  testWidgets('the month tab is reachable from the bottom bar', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(_plan('plan 1', dayCount: 2)));

    await launch(tester, AppRoutes.home);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('plan 1'), findsNothing);
    expect(
      find.text('The month calendar arrives with session logging.'),
      findsNothing,
    );
    expect(find.byKey(const Key('month-calendar')), findsOneWidget);
    expect(find.text('No workouts this month.'), findsOneWidget);
  });
}

WorkoutPlan _plan(String title, {required int dayCount}) {
  final now = DateTime.utc(2026, 8, 24, 12);
  return WorkoutPlan.create(
    title: title,
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
