import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/features/plans/plan_import_picker.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

/// Step 3: picking JSON, previewing it, and saving must write a real
/// [WorkoutPlan] and open the plan. Invalid JSON stays on the current screen.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_json_import_');
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

  Future<({PlanRepository plans, FakePlanImportPicker picker})> bootstrap(
    WidgetTester tester, {
    PickedPlanFile? file,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    instanceSeq += 1;
    final service = await db(
      tester,
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'jsonImport$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    final plans = putPlans(service.isar);
    putSessions(service.isar);
    final picker = FakePlanImportPicker(file: file);
    Get.put<PlanImportPicker>(picker, permanent: true);
    return (plans: plans, picker: picker);
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  testWidgets(
      'invalid JSON is rejected, then the shipped sample saves and opens',
      (tester) async {
    final json = await rootBundle.loadString('assets/json/plan.json');
    final env = await bootstrap(
      tester,
      file: const PickedPlanFile(
        fileName: 'broken.json',
        contents: '{ "name": "plan 1", }',
      ),
    );

    await launch(tester, AppRoutes.welcome);

    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.textContaining('not valid JSON'), findsOneWidget);
    expect(find.text('Import a plan'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);

    env.picker.file = PickedPlanFile(fileName: 'plan.json', contents: json);
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Import preview'), findsOneWidget);
    expect(find.text('plan.json'), findsOneWidget);
    expect(find.text('plan 1'), findsWidgets);
    expect(find.text('day 1- 4sar'), findsOneWidget);
    expect(
      find.text('3 × 12 kang squat + 3 × 12 leg extension'),
      findsOneWidget,
    );
    expect(find.text('3 × 12 reverse lunges+ Press'), findsOneWidget);
    expect(find.text('abs'), findsOneWidget);
    expect(find.text('corrective'), findsOneWidget);

    await tester.tap(find.text('Save plan'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('plan 1'), findsWidgets);
    expect(find.text('day 1- 4sar'), findsWidgets);

    final stored = await db(tester, env.plans.all);
    expect(stored, hasLength(1));
    final plan = stored.single;
    expect(plan.source, PlanSource.imported);
    expect(plan.title, 'plan 1');
    expect(plan.days, hasLength(1));
    expect(plan.days.single.blocks, hasLength(2));
    expect(plan.days.single.blocks[0].kind, BlockKind.superset);
    expect(
      plan.days.single.blocks[0].exercises.map((e) => e.title),
      ['kang squat', 'leg extension'],
    );
    expect(plan.commonSections.map((s) => s.title), ['abs', 'corrective']);
    expect(
      plan.commonSections.first.blocks.single.exercises.single
          .prescribedDurationSeconds,
      30,
    );
    expect(plan.days.single.dayId, isNotEmpty);
    expect(plan.days.single.blocks.first.blockId, isNotEmpty);
    expect(
      plan.days.single.blocks.first.exercises.first.prescriptionId,
      isNotEmpty,
    );
  });

  testWidgets('cancel on the import preview does not write a plan',
      (tester) async {
    final json = await rootBundle.loadString('assets/json/plan.json');
    final env = await bootstrap(
      tester,
      file: PickedPlanFile(fileName: 'plan.json', contents: json),
    );

    await launch(tester, AppRoutes.welcome);
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Import preview'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Import a plan'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);
  });

  testWidgets('canceling the file picker leaves the current screen',
      (tester) async {
    final env = await bootstrap(tester);

    await launch(tester, AppRoutes.welcome);
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Import preview'), findsNothing);
    expect(find.text('Import a plan'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);
  });

  testWidgets('a picker failure stays on the current screen with a snackbar',
      (tester) async {
    final env = await bootstrap(tester);
    env.picker.error = const PlanImportException(
      'Could not read that file. Try another JSON file.',
    );

    await launch(tester, AppRoutes.welcome);
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(
      find.text('Could not read that file. Try another JSON file.'),
      findsOneWidget,
    );
    expect(find.text('Import preview'), findsNothing);
    expect(find.text('Import a plan'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);

    env.picker.error = StateError('disk');
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.textContaining('Could not open a file:'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);
  });
}

class FakePlanImportPicker implements PlanImportPicker {
  FakePlanImportPicker({this.file, this.error});

  PickedPlanFile? file;
  Object? error;

  @override
  Future<PickedPlanFile?> pick() async {
    if (error != null) throw error!;
    return file;
  }
}
