import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/isar_plan_repository.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/plan_builder_controller.dart';
import 'package:gym_app/features/plans/plan_builder_page.dart';

import '../helpers/isar_core.dart';
import '../helpers/ports.dart';

void main() {
  test('openNew persists an untitled draft in Isar', () async {
    await ensureIsarCore();
    final dir = await Directory.systemTemp.createTemp('gym_app_add_plan_isar_');
    final service = await IsarService.init(
      directory: dir.path,
      name: 'addPlanIsar',
    );
    final plans = IsarPlanRepository(service.isar);
    addTearDown(() async {
      await service.close(deleteFromDisk: true);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final controller = await PlanBuilderController.openNew(plans);
    final stored = await plans.all();
    expect(stored, hasLength(1));
    expect(stored.single.status, PlanStatus.draft);
    expect(stored.single.title, isEmpty);
    expect(stored.single.displayTitle, untitledPlanTitle);
    controller.dispose();
  });

  testWidgets('builder writes a draft immediately and keeps an empty name invalid',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final plans = MemoryPlanRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderPage(ports: testPorts(plans: plans)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Create plan'), findsOneWidget);
    expect(find.byKey(const Key('plan-builder-stepper')), findsOneWidget);
    expect((await plans.all()).single.status, PlanStatus.draft);
    expect((await plans.all()).single.title, isEmpty);

    await tester.ensureVisible(find.byKey(const Key('continue-plan-details')));
    await tester.tap(find.byKey(const Key('continue-plan-details')));
    await tester.pump();
    expect(find.byKey(const Key('plan-name-field')), findsOneWidget);
    expect((await plans.all()).single.status, PlanStatus.draft);
  });

  test('flush trims the plan name and activate writes an active plan', () async {
    final plans = MemoryPlanRepository();
    final controller = await PlanBuilderController.openNew(plans);
    controller.setTitle('  Push  ');
    final dayId = controller.plan.days.single.dayId;
    controller.setDayBlocks(dayId, [
      ExerciseBlock.create(
        blockId: 'b1',
        kind: BlockKind.single,
        exercises: [
          ExercisePrescription.create(
            prescriptionId: 'p1',
            title: 'squat',
            prescribedSets: 3,
            prescribedReps: 10,
          ),
        ],
      ),
    ]);
    expect(await controller.activate(), isTrue);
    final stored = (await plans.all()).single;
    expect(stored.title, 'Push');
    expect(stored.status, PlanStatus.active);
    expect(stored.days.single.blocks, isNotEmpty);
    controller.dispose();
  });
}
