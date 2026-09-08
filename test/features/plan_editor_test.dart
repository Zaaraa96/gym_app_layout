import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_lifecycle.dart';
import 'package:gym_app/domain/session_repository.dart';
import 'package:gym_app/features/plans/day_editor_page.dart';
import 'package:gym_app/features/plans/exercise_editor_page.dart';
import 'package:gym_app/features/plans/exercise_media_picker.dart';
import 'package:gym_app/features/plans/plan_page.dart';
import 'package:gym_app/main.dart';

import '../helpers/exercise_editor.dart';
import '../helpers/fake_exercise_gallery_picker.dart';
import '../helpers/isar_core.dart';

/// A stored plan can be opened, given more days, and filled with exercises.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_plan_editor_');
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
        name: 'planEditor$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    putSessions(service.isar);
    Get.put<ExerciseGalleryPicker>(
      FakeExerciseGalleryPicker(),
      permanent: true,
    );
    return putPlans(service.isar);
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  WorkoutPlan samplePlan() {
    final now = DateTime.utc(2026, 8, 24, 12);
    return WorkoutPlan.create(
      title: 'Push week',
      source: PlanSource.created,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          summary: 'chest',
        ),
      ],
    );
  }

  WorkoutPlan loggedPlan() {
    final now = DateTime.utc(2026, 8, 24, 12);
    return WorkoutPlan.create(
      title: 'Push week',
      source: PlanSource.created,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          summary: 'chest',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-1',
                  title: 'kang squat',
                  prescribedSets: 3,
                  prescribedReps: 12,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> confirmDeletePlan(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('delete-plan')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-delete-plan')));
    await tester.pump();
    await settle(tester);
    // Isar delete finishes during settle, then offAllNamed starts the home
    // transition. One more settle so the bottom nav is on-screen to tap.
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }

  testWidgets('tapping a plan opens it and a day can be added', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('chest'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-day')));
    await tester.pump();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first,
      'Day 2',
    );
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .at(1),
      'shoulders',
    );
    await tester.tap(find.text('Save day'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.editDay);
    expect(find.text('Day 2'), findsWidgets);

    await tester.pageBack();
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.text('shoulders'), findsOneWidget);

    final stored = await db(tester, plans.all);
    expect(stored.single.days, hasLength(2));
    expect(stored.single.days.last.title, 'Day 2');
  });

  testWidgets('a day can gain a reps exercise and a duration exercise',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.day);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.editDay);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'kang squat');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('kang squat'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'plank');
    await selectTimed(tester);
    await tester.enterText(exerciseDurationField(), '45');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(find.text('x45s'), findsWidgets);

    final stored = await db(tester, plans.all);
    final day = stored.single.days.single;
    expect(day.blocks, hasLength(2));
    expect(day.blocks.first.exercises.single.title, 'kang squat');
    expect(
      day.blocks.first.exercises.single.mediaUri,
      'assets/image/exercises/kang-squat.png',
    );
    expect(day.blocks.first.exercises.single.prescribedReps, 12);
    expect(day.blocks.last.exercises.single.prescribedDurationSeconds, 45);
    expect(
      day.blocks.last.exercises.single.mediaUri,
      'assets/image/exercises/plank.png',
    );
    expect(day.blocks.last.kind, BlockKind.single);
    expect(day.blocks.last.mediaUri, isNull);
  });

  testWidgets('saving an exercise without a name stays on the dialog',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-editor-commit')));
    await tester.pump();

    expect(find.textContaining('Add a name for Movement A'), findsOneWidget);
    expect(find.byType(ExerciseEditorPage), findsOneWidget);
    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.blocks, isEmpty);
  });

  testWidgets('an exercise can be deleted from the day editor', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'kang squat');
    await commitExerciseEditor(tester);
    await settle(tester);
    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('kang squat'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Delete exercise'));
    await tester.pump();
    await confirmDeleteFromDayList(tester);
    await settle(tester);

    expect(find.text('kang squat'), findsNothing);
    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.blocks, isEmpty);
  });

  testWidgets('exercise dialog can pick a bundled preview asset',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-media-picker')));
    await tester.pumpAndSettle();
    final deadlift = find.byKey(const Key('bundled-asset-deadlift'));
    await tester.scrollUntilVisible(
      deadlift,
      80,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(deadlift);
    await tester.pumpAndSettle();

    await tester.enterText(exerciseNameField(), 'heavy deadlift');
    await commitExerciseEditor(tester);
    await settle(tester);

    final stored = await db(tester, plans.all);
    final block = stored.single.days.single.blocks.single;
    expect(
      block.exercises.single.mediaUri,
      'assets/image/exercises/deadlift.png',
    );
    expect(block.exercises.single.mediaSource, ExerciseMediaSource.asset);
    expect(block.mediaUri, isNull);
  });

  testWidgets('a plan can be renamed and a day can be deleted', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byTooltip('Rename plan'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'Pull week',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Pull week'), findsWidgets);

    await tester.tap(find.byTooltip('Delete day'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Day 1'), findsNothing);
    expect(
      find.text('No days yet. Add a day, then fill it with exercises.'),
      findsOneWidget,
    );

    final stored = await db(tester, plans.all);
    expect(stored.single.title, 'Pull week');
    expect(stored.single.days, isEmpty);
    expect(
      stored.single.updatedAt.toUtc().difference(DateTime.now().toUtc()).abs(),
      lessThan(const Duration(seconds: 5)),
    );
  });

  testWidgets('a day can gain a superset of two movements', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'bench press');
    await selectSuperset(tester);
    await tester.enterText(exerciseNameField(1), 'bent over row');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('SUPERSET'),
      ),
      findsOneWidget,
    );
    expect(find.text('bench press'), findsWidgets);
    expect(find.text('bent over row'), findsWidgets);

    final stored = await db(tester, plans.all);
    final block = stored.single.days.single.blocks.single;
    expect(block.kind, BlockKind.superset);
    expect(block.exercises.map((item) => item.title).toList(),
        ['bench press', 'bent over row']);
  });

  testWidgets('a superset can hold more than two movements', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'bench press');
    await selectSuperset(tester);
    await tester.enterText(exerciseNameField(1), 'bent over row');
    await tester.ensureVisible(find.byKey(const Key('add-movement')));
    await tester.tap(find.byKey(const Key('add-movement')));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(2), 'face pull');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('SUPERSET'),
      ),
      findsOneWidget,
    );
    expect(find.text('face pull'), findsWidgets);

    final stored = await db(tester, plans.all);
    final block = stored.single.days.single.blocks.single;
    expect(block.kind, BlockKind.superset);
    expect(
      block.exercises.map((item) => item.title).toList(),
      ['bench press', 'bent over row', 'face pull'],
    );
  });

  testWidgets('a plan can gain a common section with a duration exercise', skip: true, (tester) async {});

  testWidgets('a common section can be deleted from the plan', skip: true, (tester) async {});

  testWidgets('deleting an exercise removes it from the stored day',
      (tester) async {
    final plans = await bootstrap(tester);
    final now = DateTime.utc(2026, 8, 24, 12);
    await db(
      tester,
      () => plans.save(
        WorkoutPlan.create(
          title: 'Push week',
          source: PlanSource.created,
          createdAt: now,
          updatedAt: now,
          days: [
            PlanDay.create(
              dayId: 'day-1',
              title: 'Day 1',
              blocks: [
                ExerciseBlock.create(
                  blockId: 'block-keep',
                  kind: BlockKind.single,
                  exercises: [
                    ExercisePrescription.create(
                      prescriptionId: 'p-keep',
                      title: 'bench press',
                      prescribedSets: 3,
                      prescribedReps: 8,
                    ),
                  ],
                ),
                ExerciseBlock.create(
                  blockId: 'block-drop',
                  kind: BlockKind.single,
                  exercises: [
                    ExercisePrescription.create(
                      prescriptionId: 'p-drop',
                      title: 'skull crusher',
                      prescribedSets: 3,
                      prescribedReps: 10,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    expect(find.text('bench press'), findsOneWidget);
    expect(find.text('skull crusher'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete exercise').last);
    await tester.pump();
    await confirmDeleteFromDayList(tester);
    await settle(tester);

    expect(find.text('skull crusher'), findsNothing);
    expect(find.text('bench press'), findsOneWidget);

    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.blocks, hasLength(1));
    expect(
      stored.single.days.single.blocks.single.exercises.single.title,
      'bench press',
    );
  });

  testWidgets('canceling delete day leaves the stored day in place',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Day 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete day'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('chest'), findsOneWidget);
    final stored = await db(tester, plans.all);
    expect(stored.single.days, hasLength(1));
    expect(stored.single.days.single.dayId, 'day-1');
  });

  testWidgets('saving a day persists an edited summary', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Summary (optional)'),
      'upper body',
    );
    await tester.tap(find.text('Done'));
    await tester.pump();
    await settle(tester);

    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.title, 'Day 1');
    expect(stored.single.days.single.summary, 'upper body');
  });

  testWidgets('default sets and reps are 3 × 12 and timed defaults to 30s',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'mystery move');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('mystery move'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'hold-ish');
    await selectTimed(tester);
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(find.text('hold-ish'), findsWidgets);

    final stored = await db(tester, plans.all);
    final blocks = stored.single.days.single.blocks;
    expect(blocks, hasLength(2));
    expect(blocks.first.exercises.single.prescribedSets, 3);
    expect(blocks.first.exercises.single.prescribedReps, 12);
    expect(blocks.last.exercises.single.prescribedSets, 3);
    expect(blocks.last.exercises.single.prescribedDurationSeconds, 30);
    expect(blocks.last.exercises.single.prescribedReps, isNull);
  });

  testWidgets('saving a blank day title keeps the previous name',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Day name'), '   ');
    await tester.tap(find.text('Done'));
    await tester.pump();
    await settle(tester);

    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.title, 'Day 1');
    expect(stored.single.days.single.summary, 'chest');
  });

  testWidgets('a missing plan says it is no longer here', (tester) async {
    await bootstrap(tester);

    await tester.pumpWidget(
      GetMaterialApp(
        home: PlanPage(planId: 'missing-plan', ports: Get.find<AppPorts>()),
      ),
    );
    await settle(tester);

    expect(find.text('This plan is no longer here.'), findsOneWidget);
  });

  testWidgets('deleting a common section removes it from the stored plan', skip: true, (tester) async {});

  testWidgets('cancel rename and a whitespace title leave the plan name',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byTooltip('Rename plan'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    await settle(tester);
    expect(find.text('Push week'), findsWidgets);

    await tester.tap(find.byTooltip('Rename plan'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      '   ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Push week'), findsWidgets);
    final stored = await db(tester, plans.all);
    expect(stored.single.title, 'Push week');
  });

  testWidgets('cancel on add-day does not write a day', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byKey(const Key('add-day')));
    await tester.pump();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first,
      'Should not save',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    await settle(tester);

    expect(find.text('Should not save'), findsNothing);
    expect(find.text('Day 1'), findsOneWidget);
    final stored = await db(tester, plans.all);
    expect(stored.single.days, hasLength(1));
    expect(stored.single.days.single.title, 'Day 1');
  });

  testWidgets('cancel on delete section leaves the section', skip: true, (tester) async {});

  testWidgets('cancel on add exercise does not persist a typed name',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'ghost squat');
    await tester.tap(find.byTooltip('Close exercise editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();

    expect(find.text('ghost squat'), findsNothing);
    expect(find.byType(ExerciseEditorPage), findsNothing);
    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.blocks, isEmpty);
  });

  testWidgets(
      'editing an exercise keeps its prescription id and updates the title',
      (tester) async {
    final plans = await bootstrap(tester);
    final now = DateTime.utc(2026, 8, 24, 12);
    await db(
      tester,
      () => plans.save(
        WorkoutPlan.create(
          title: 'Push week',
          source: PlanSource.created,
          createdAt: now,
          updatedAt: now,
          days: [
            PlanDay.create(
              dayId: 'day-1',
              title: 'Day 1',
              blocks: [
                ExerciseBlock.create(
                  blockId: 'block-keep',
                  kind: BlockKind.single,
                  exercises: [
                    ExercisePrescription.create(
                      prescriptionId: 'p-keep',
                      title: 'bench press',
                      prescribedSets: 3,
                      prescribedReps: 8,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byTooltip('Edit exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'incline bench');
    await tester.enterText(exerciseSetsField(), '4');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(find.text('incline bench'), findsWidgets);
    expect(find.text('bench press'), findsNothing);

    final stored = await db(tester, plans.all);
    final exercise = stored.single.days.single.blocks.single.exercises.single;
    expect(exercise.prescriptionId, 'p-keep');
    expect(exercise.title, 'incline bench');
    expect(exercise.prescribedSets, 4);
    expect(exercise.prescribedReps, 8);
  });

  testWidgets('a blank add-day title falls back to Day N', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byKey(const Key('add-day')));
    await tester.pump();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first,
      '   ',
    );
    await tester.tap(find.text('Save day'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.editDay);
    expect(find.text('Day 2'), findsWidgets);

    await tester.pageBack();
    await tester.pump();
    await settle(tester);

    final stored = await db(tester, plans.all);
    expect(stored.single.days, hasLength(2));
    expect(stored.single.days.last.title, 'Day 2');
  });

  testWidgets('a superset with a blank second name stays in the dialog',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'bench press');
    await selectSuperset(tester);
    await tester.tap(find.byKey(const Key('exercise-editor-commit')));
    await tester.pump();

    expect(
      find.textContaining('Add a name for Movement B'),
      findsWidgets,
    );
    expect(find.byType(ExerciseEditorPage), findsOneWidget);
    final stored = await db(tester, plans.all);
    expect(stored.single.days.single.blocks, isEmpty);
  });

  testWidgets('editing an exercise keeps ids and can switch it to duration', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final now = DateTime.utc(2026, 8, 24, 12);
    await db(
      tester,
      () => plans.save(
        WorkoutPlan.create(
          title: 'Push week',
          source: PlanSource.created,
          createdAt: now,
          updatedAt: now,
          days: [
            PlanDay.create(
              dayId: 'day-1',
              title: 'Day 1',
              blocks: [
                ExerciseBlock.create(
                  blockId: 'block-keep',
                  kind: BlockKind.single,
                  exercises: [
                    ExercisePrescription.create(
                      prescriptionId: 'p-keep',
                      title: 'bench press',
                      prescribedSets: 3,
                      prescribedReps: 8,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byTooltip('Edit exercise'));
    await tester.pumpAndSettle();
    expect(find.text('Edit exercise'), findsOneWidget);

    await tester.ensureVisible(find.text('Timed').first);
    await selectTimed(tester);
    await tester.enterText(exerciseDurationField(), '45');
    await commitExerciseEditor(tester);
    await settle(tester);

    expect(find.text('x45s'), findsOneWidget);
    final stored = await db(tester, plans.all);
    final block = stored.single.days.single.blocks.single;
    expect(block.blockId, 'block-keep');
    expect(block.exercises.single.prescriptionId, 'p-keep');
    expect(block.exercises.single.prescribedDurationSeconds, 45);
    expect(block.exercises.single.prescribedReps, isNull);
  });

  testWidgets('deleting a plan removes it from home and drops the count',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    await confirmDeletePlan(tester);

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('Push week'), findsNothing);
    expect(
      find.text(
        'No plans yet. Start with a beginner template, import one, or create your first.',
      ),
      findsOneWidget,
    );
    expect(await db(tester, plans.count), 0);
  });

  testWidgets('canceling delete plan leaves the stored plan in place',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('delete-plan')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('Push week'), findsWidgets);
    expect(find.text('Day 1'), findsOneWidget);
    expect(await db(tester, plans.count), 1);
    final stored = await db(tester, plans.all);
    expect(stored.single.title, 'Push week');
    expect(stored.single.days.single.dayId, 'day-1');
  });

  testWidgets(
      'deleting a plan keeps completed sessions on Month with the title snapshot',
      (tester) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final plan = loggedPlan();
    await db(tester, () => plans.save(plan));
    final startedAt = DateTime.now().toUtc();
    await db(
      tester,
      () async {
        final session = await SessionLifecycle(sessions).start(
          plan: plan,
          planDayId: 'day-1',
          startedAt: startedAt,
        );
        final log = session.exerciseLogs.first;
        log.sets = [
          SetLog.create(
            setIndex: 1,
            completedAt: startedAt,
            reps: 12,
            weightKg: 40,
          ),
        ];
        log.difficulty = 3;
        log.completedAt = startedAt;
        session.exerciseLogs = [log];
        session.status = SessionStatus.completed;
        session.endedAt = startedAt;
        await sessions.save(session);
      },
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await confirmDeletePlan(tester);

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('Push week'), findsNothing);
    expect(await db(tester, plans.count), 0);

    final remaining = await db(tester, () => sessions.completedNewestFirst());
    expect(remaining, hasLength(1));
    expect(remaining.single.planTitleSnapshot, 'Push week');
    expect(remaining.single.status, SessionStatus.completed);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Month'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);

    final day = startedAt.day;
    expect(find.byKey(Key('month-dot-$day')), findsOneWidget);

    await tester.tap(find.byKey(Key('month-day-$day')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Push week'), findsWidgets);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets(
      'deleting a plan leaves an in-progress session on the Continue banner',
      (tester) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final plan = loggedPlan();
    await db(tester, () => plans.save(plan));
    await db(
      tester,
      () => SessionLifecycle(sessions).start(
        plan: plan,
        planDayId: 'day-1',
        startedAt: DateTime.now().toUtc(),
      ),
    );

    await launch(tester, AppRoutes.home);
    expect(find.byKey(const Key('continue-banner')), findsOneWidget);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);
    await confirmDeletePlan(tester);

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.text('Push week'), findsNothing);
    expect(await db(tester, plans.count), 0);
    expect(await db(tester, () => sessions.inProgress()), isNotNull);
    expect(find.byKey(const Key('continue-banner')), findsOneWidget);

    await tester.tap(find.text('Continue workout'));
    await tester.pump();
    await settle(tester);

    expect(find.text('kang squat  ·  set 1 of 3'), findsOneWidget);
    expect(find.text('Log set'), findsOneWidget);
    expect(
      (await db(tester, () => sessions.inProgress()))!.status,
      SessionStatus.inProgress,
    );
  });

  testWidgets('a section saved without a title gets Section 1', skip: true, (tester) async {});
}

