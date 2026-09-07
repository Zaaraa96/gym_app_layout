import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
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
      dir.deleteSync(recursive: true);
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
    putSessions(service.isar);
    return putPlans(service.isar);
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  testWidgets('builder writes a draft immediately and keeps an empty name invalid',
      (tester) async {
    final plans = await bootstrap(tester);
    await launch(tester, AppRoutes.newPlan);

    expect(find.text('Create plan'), findsOneWidget);
    expect(find.byKey(const Key('plan-builder-stepper')), findsOneWidget);

    final stored = await db(tester, plans.all);
    expect(stored, hasLength(1));
    expect(stored.single.status, PlanStatus.draft);
    expect(stored.single.title, isEmpty);

    await tester.tap(find.byKey(const Key('continue-plan-details')));
    await tester.pump();
    expect(find.byKey(const Key('plan-name-field')), findsOneWidget);
  });

  testWidgets('create plan activates a completed draft', (tester) async {
    final plans = await bootstrap(tester);
    await launch(tester, AppRoutes.newPlan);

    await tester.enterText(find.byKey(const Key('plan-name-field')), '  Push  ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue-plan-details')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise or superset'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ).first,
      'squat',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('CONTINUE').last);
    await tester.pump();
    await settle(tester);

    expect(find.text('CREATE PLAN'), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-plan')));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('Push'), findsWidgets);

    final stored = await db(tester, plans.all);
    expect(stored.single.title, 'Push');
    expect(stored.single.status, PlanStatus.active);
    expect(stored.single.source, PlanSource.created);
    expect(stored.single.days.single.blocks, isNotEmpty);
  });
}
