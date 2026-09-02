import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/features/plans/plan_import_picker.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

/// Cancel and picker failures must not write a plan or leave welcome.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_json_cancel_');
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
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    instanceSeq += 1;
    final service = await db(
      tester,
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'jsonCancel$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    final plans = putPlans(service.isar);
    putSessions(service.isar);
    final picker = FakePlanImportPicker();
    Get.put<PlanImportPicker>(picker, permanent: true);
    return (plans: plans, picker: picker);
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.welcome));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  testWidgets('picker cancel, picker errors, and preview cancel do not save',
      (tester) async {
    final env = await bootstrap(tester);
    await launch(tester);

    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Import preview'), findsNothing);
    expect(find.text('Import a plan'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);

    env.picker.error = const PlanImportException(
      'Could not read that file. Try another JSON file.',
    );
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(
      find.text('Could not read that file. Try another JSON file.'),
      findsOneWidget,
    );
    expect(find.text('Import preview'), findsNothing);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);

    env.picker.error = StateError('disk');
    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.textContaining('Could not open a file:'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.welcome);
    expect(await db(tester, env.plans.count), 0);

    final json = await tester.runAsync(
      () => rootBundle.loadString('assets/json/plan.json'),
    );
    env.picker
      ..error = null
      ..file = PickedPlanFile(fileName: 'plan.json', contents: json!);

    await tester.tap(find.text('Import a plan'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Import preview'), findsOneWidget);
    final cancel = find.widgetWithText(OutlinedButton, 'Cancel');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Import a plan'), findsOneWidget);
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
