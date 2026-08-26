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

/// Step 4: plan day cards open a read-only day preview with reps and duration
/// rows loaded from Isar. Edit stays a separate action.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_day_preview_');
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

  Future<PlanRepository> bootstrap(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    instanceSeq += 1;
    final service = await db(
      tester,
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'dayPreview$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    return Get.put<PlanRepository>(
      PlanRepository(service.isar),
      permanent: true,
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> launch(WidgetTester tester, String route) async {
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  WorkoutPlan samplePlan() {
    final now = DateTime.utc(2026, 8, 26, 12);
    return WorkoutPlan.create(
      title: 'plan 1',
      source: PlanSource.imported,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'day 1- 4sar',
          summary: 'legs',
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
            ExerciseBlock.create(
              blockId: 'block-hold',
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

  testWidgets(
      'opening a day shows reps, duration, and the start CTA from Isar',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));

    await launch(tester, AppRoutes.home);
    expect(find.text('plan 1'), findsOneWidget);

    await tester.tap(find.text('plan 1'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('day 1- 4sar'), findsOneWidget);
    expect(find.text('legs'), findsOneWidget);
    expect(
      find.text('3 × 12 kang squat + 3 × 12 leg extension'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.day);
    expect(find.text('day 1- 4sar'), findsWidgets);
    expect(find.text('legs'), findsWidgets);
    expect(find.text('kang squat'), findsOneWidget);
    expect(find.text('x12'), findsNWidgets(2));
    expect(find.text('leg extension'), findsOneWidget);
    expect(find.text('plank'), findsOneWidget);
    expect(find.text('x30s'), findsOneWidget);
    expect(find.byKey(const Key('block-row-block-ss')), findsOneWidget);
    expect(find.byKey(const Key('block-row-block-hold')), findsOneWidget);
    expect(
      find.text('Common sections can be included when you start.'),
      findsOneWidget,
    );
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    expect(find.text('Starting a workout comes next'), findsWidgets);
  });

  testWidgets('edit day from preview opens the day editor', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('plan 1'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Edit day'), findsOneWidget);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.editDay);
    expect(find.text('Add exercise'), findsWidgets);
  });
}
