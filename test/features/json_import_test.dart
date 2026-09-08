import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/features/plans/plan_import_picker.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

/// Import salvages files into Create plan, then CREATE PLAN activates.
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
      'trailing-comma JSON opens Create plan; sample then activates',
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

    expect(find.text('Create plan'), findsOneWidget);
    expect(find.text('Import didn’t go as planned.'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.newPlan);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await settle(tester);

    env.picker.file = PickedPlanFile(fileName: 'plan.json', contents: json);
    await tester.tap(find.text('Import'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Create plan'), findsOneWidget);
    expect(find.text('plan 1'), findsWidgets);
    expect(find.text('day 1- 4sar'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('create-plan')));
    await tester.tap(find.byKey(const Key('create-plan')));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('plan 1'), findsWidgets);
    expect(find.text('day 1- 4sar'), findsWidgets);

    final stored = await db(tester, env.plans.all);
    expect(stored.where((p) => p.status == PlanStatus.active), hasLength(1));
    final plan = stored.firstWhere((p) => p.status == PlanStatus.active);
    expect(plan.source, PlanSource.imported);
    expect(plan.title, 'plan 1');
    expect(plan.days, hasLength(3));
    expect(plan.days.first.blocks, hasLength(2));
    expect(plan.days.first.blocks[0].kind, BlockKind.superset);
    expect(
      plan.days.first.blocks[0].exercises.map((e) => e.title),
      ['kang squat', 'leg extension'],
    );
    expect(plan.days.map((day) => day.title), containsAll(['abs', 'corrective']));
  });
}

class FakePlanImportPicker implements PlanImportPicker {
  FakePlanImportPicker({this.file});

  PickedPlanFile? file;

  @override
  Future<PickedPlanFile?> pick() async => file;
}
