import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/main.dart';
import 'package:isar/isar.dart';

/// Saving a new plan must write a [WorkoutPlan] and open it for day-by-day editing.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } on IsarError {
      // Continue; Isar.open will fail loudly if the native lib is missing.
    }
    tempDir = await Directory.systemTemp.createTemp('gym_app_add_plan_');
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

    instanceSeq += 1;
    final service = await db(
      tester,
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'addPlan$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    return Get.put<PlanRepository>(
      PlanRepository(service.isar),
      permanent: true,
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
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

  testWidgets('save writes the plan and opens the plans home', (tester) async {
    final plans = await bootstrap(tester);
    await launch(tester, AppRoutes.newPlan);

    await tester.enterText(find.byType(TextFormField).first, '  Push  ');
    await tester.enterText(find.byType(TextFormField).at(1), 'chest and triceps');
    await tester.tap(find.text('save'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('Push'), findsWidgets);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('chest and triceps'), findsWidgets);

    final stored = await db(tester, plans.all);
    expect(stored, hasLength(1));
    expect(stored.single.title, 'Push');
    expect(stored.single.source, PlanSource.created);
    expect(stored.single.days.single.summary, 'chest and triceps');
  });

  testWidgets('save without a title stays on the form', (tester) async {
    await bootstrap(tester);
    await launch(tester, AppRoutes.newPlan);

    await tester.tap(find.text('save'));
    await tester.pump();

    expect(find.text('Add a title before saving'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.newPlan);
  });
}
