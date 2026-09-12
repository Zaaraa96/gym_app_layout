import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_validation.dart';
import 'package:gym_app/domain/today_suggestion.dart';
import 'package:gym_app/features/plans/plan_builder_controller.dart';
import 'package:gym_app/features/plans/plan_builder_page.dart';
import 'package:gym_app/features/plans/plans_home_page.dart';

import '../helpers/ports.dart';

void main() {
  test('opening the builder creates a draft with an empty name field', () async {
    final plans = MemoryPlanRepository();
    final controller = await PlanBuilderController.openNew(plans);
    expect(controller.plan.isDraft, isTrue);
    expect(controller.plan.title, isEmpty);
    expect(controller.plan.displayTitle, untitledPlanTitle);
    expect(await plans.count(), 1);
    expect((await plans.all()).single.status, PlanStatus.draft);
  });

  test('flush failure keeps local form state and can retry', () async {
    final plans = _FailingPlans();
    final controller = PlanBuilderController(
      plans: plans,
      plan: PlanBuilderController.createDraft(newId: () => 'day-1'),
    );
    controller.setTitle('Push');
    await controller.flush();
    expect(controller.saveStatus, DraftSaveStatus.failed);
    expect(controller.plan.title, 'Push');
    plans.failSaves = false;
    await controller.retrySave();
    expect(controller.saveStatus, DraftSaveStatus.saved);
    expect((await plans.all()).single.title, 'Push');
  });

  test('activate is atomic and blocked while required issues remain', () async {
    final plans = MemoryPlanRepository();
    final controller = await PlanBuilderController.openNew(plans);
    expect(await controller.activate(), isFalse);
    expect(controller.plan.status, PlanStatus.draft);
    controller.setTitle('Push');
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
            targetAreaIds: const ['quads', 'glutes'],
          ),
        ],
      ),
    ]);
    expect(planCanActivate(controller.plan), isTrue);
    expect(await controller.activate(), isTrue);
    await controller.flush();
    expect((await plans.all()).single.status, PlanStatus.active);
  });

  test('reorderBlocks uses onReorderItem indexes as-is', () async {
    final plans = MemoryPlanRepository();
    final controller = await PlanBuilderController.openNew(plans);
    final dayId = controller.plan.days.single.dayId;
    controller.setDayBlocks(dayId, [
      ExerciseBlock.create(blockId: 'a', kind: BlockKind.single),
      ExerciseBlock.create(blockId: 'b', kind: BlockKind.single),
      ExerciseBlock.create(blockId: 'c', kind: BlockKind.single),
    ]);
    controller.reorderBlocks(dayId, 0, 2);
    expect(
      controller.plan.days.single.blocks.map((block) => block.blockId),
      ['b', 'c', 'a'],
    );
    controller.dispose();
  });

  test('today suggestion ignores drafts', () {
    final now = DateTime.utc(2026, 9, 7);
    final draft = WorkoutPlan.create(
      title: 'Draft',
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p',
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(suggestToday(plans: [draft]), isNull);
    expect(dayCanStart(draft, draft.days.single), isFalse);
  });

  testWidgets('stepper shows complete, current, incomplete, and untouched',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final plans = MemoryPlanRepository();
    final now = DateTime.utc(2026, 9, 7);
    final plan = WorkoutPlan.create(
      title: 'Strength Builder',
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p1',
                  title: 'bench press',
                  prescribedSets: 4,
                  prescribedReps: 8,
                  targetAreaIds: const ['chest', 'triceps'],
                ),
              ],
            ),
          ],
        ),
        PlanDay.create(
          dayId: 'day-2',
          title: 'Upper',
        ),
      ],
    );
    await plans.save(plan);
    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderPage(
          ports: testPorts(plans: plans),
          planId: plan.uuid,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Create plan'), findsOneWidget);
    expect(find.text('Plan details'), findsOneWidget);
    expect(find.text('Upper'), findsWidgets);
    expect(find.text('Add at least one exercise.'), findsWidgets);

    await tester.tap(find.byKey(const Key('step-details')));
    await tester.pump();
    expect(find.text('Needs attention'), findsWidgets);
    expect(find.text('Review & create'), findsOneWidget);

    await tester.tap(find.text('Review & create'));
    await tester.pump();
    expect(find.text('Fix this'), findsOneWidget);
    expect(find.text('Finish plan'), findsOneWidget);
    expect(find.text('CREATE PLAN'), findsNothing);
    final create = tester.widget<FilledButton>(
      find.byKey(const Key('create-plan')),
    );
    expect(create.onPressed, isNull);
    expect(find.byKey(const Key('add-another-day')), findsOneWidget);
    await tester.tap(find.text('Fix this'));
    await tester.pump();
    expect(find.text('Add exercise'), findsOneWidget);
    final continueDay = tester.widget<FilledButton>(
      find.byKey(const Key('continue-day-day-2')),
    );
    expect(continueDay.onPressed, isNull);

    await tester.tap(find.text('Review & create'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-another-day')));
    await tester.pump();
    expect(find.text('Day 3'), findsWidgets);
    expect(find.text('Add at least one exercise.'), findsWidgets);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'CONTINUE')).onPressed,
      isNull,
    );
  });

  testWidgets('expanded day with a saved block keeps its card laid out',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final plans = MemoryPlanRepository();
    final now = DateTime.utc(2026, 9, 7);
    final plan = WorkoutPlan.create(
      title: 'Editor demo',
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.superset,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p1',
                  title: 'bench press',
                  prescribedSets: 3,
                  prescribedReps: 8,
                  targetAreaIds: const ['chest'],
                ),
                ExercisePrescription.create(
                  prescriptionId: 'p2',
                  title: 'rdl',
                  prescribedSets: 3,
                  prescribedReps: 10,
                  targetAreaIds: const ['glutes', 'hamstrings'],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await plans.save(plan);
    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderPage(
          ports: testPorts(plans: plans),
          planId: plan.uuid,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('step-day-1')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('SUPERSET'), findsOneWidget);
    expect(find.text('bench press'), findsOneWidget);
    expect(find.text('rdl'), findsOneWidget);
    expect(find.byKey(const Key('add-exercise-day-1')), findsOneWidget);
    expect(find.byTooltip('Edit superset'), findsOneWidget);
    expect(find.byTooltip('Move up'), findsOneWidget);

    final continueDay = tester.widget<FilledButton>(
      find.byKey(const Key('continue-day-day-1')),
    );
    expect(continueDay.onPressed, isNotNull);

    await tester.tap(find.byTooltip('Delete superset'));
    await tester.pump();
    expect(find.text('Remove this superset from the day?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-exercise')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('SUPERSET'), findsNothing);
    expect(find.text('Add at least one exercise.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('continue-day-day-1')))
          .onPressed,
      isNull,
    );
    expect((await plans.byUuid(plan.uuid))!.days.single.blocks, isEmpty);
  });

  testWidgets('resuming an untitled draft opens Plan details', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final plans = MemoryPlanRepository();
    final now = DateTime.utc(2026, 9, 7);
    final draft = WorkoutPlan.create(
      title: '',
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [PlanDay.create(dayId: 'day-1', title: 'Day 1')],
    );
    await plans.save(draft);

    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderPage(
          ports: testPorts(plans: plans),
          planId: draft.uuid,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Create plan'), findsOneWidget);
    expect(find.text('Plan details'), findsOneWidget);
    expect(find.byKey(const Key('plan-name-field')), findsOneWidget);
    expect(find.text('Finish plan'), findsNothing);

    await tester.enterText(find.byKey(const Key('plan-name-field')), 'Scratch week');
    await tester.pump();
    expect(find.text('Scratch week'), findsOneWidget);
  });

  testWidgets('opening a ready imported draft lands on Finish plan', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final plans = MemoryPlanRepository();
    final now = DateTime.utc(2026, 9, 7);
    final draft = WorkoutPlan.create(
      title: 'Ready import',
      source: PlanSource.imported,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p1',
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 10,
                  targetAreaIds: const ['quads'],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await plans.save(draft);

    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderPage(
          ports: testPorts(plans: plans),
          planId: draft.uuid,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Finish plan'), findsOneWidget);
    expect(find.byKey(const Key('create-plan')), findsOneWidget);
    expect(find.byKey(const Key('plan-name-field')), findsNothing);
  });

  testWidgets('Plans lists drafts with Resume and Delete', (tester) async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final now = DateTime.utc(2026, 9, 7);
    final draft = WorkoutPlan.create(
      title: '',
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [PlanDay.create(dayId: 'day-1', title: 'Day 1')],
    );
    await plans.save(draft);

    await tester.pumpWidget(
      MaterialApp(
        home: PlansHomePage(
          ports: testPorts(plans: plans, sessions: sessions),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(untitledPlanTitle), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byKey(const Key('today-card')), findsNothing);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.text('Delete this draft?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-draft')));
    await tester.pump();
    await tester.pump();
    expect(await plans.count(), 0);
  });
}

class _FailingPlans extends MemoryPlanRepository {
  var failSaves = true;

  @override
  Future<int> save(WorkoutPlan plan) {
    if (failSaves) {
      throw StateError('offline');
    }
    return super.save(plan);
  }
}
