import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/features/plans/day_editor_page.dart';
import 'package:gym_app/features/plans/exercise_media_picker.dart';
import 'package:gym_app/main.dart';

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
    Get.put<PlanRepository>(
      PlanRepository(service.isar),
      permanent: true,
    );
    Get.put<ExerciseGalleryPicker>(
      FakeExerciseGalleryPicker(),
      permanent: true,
    );
    return Get.find<PlanRepository>();
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
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
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ).first,
      'Day 2',
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ).at(1),
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

    Finder dialogField() => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );

    await tester.tap(find.text('Add exercise'));
    await tester.pump();
    await tester.enterText(dialogField().first, 'kang squat');
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('3 × 12 kang squat'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pump();
    await tester.enterText(dialogField().first, 'plank');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Duration').first);
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextFormField, 'seconds'),
      ),
      '45',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    expect(find.text('3 × 45s plank'), findsWidgets);

    final stored = await db(tester, plans.all);
    final day = stored.single.days.single;
    expect(day.blocks, hasLength(2));
    expect(day.blocks.first.exercises.single.title, 'kang squat');
    expect(day.blocks.first.exercises.single.prescribedReps, 12);
    expect(day.blocks.last.exercises.single.prescribedDurationSeconds, 45);
    expect(day.blocks.last.kind, BlockKind.single);
    expect(day.blocks.last.mediaUri, 'assets/image/exercises/plank.svg');
  });

  testWidgets('exercise dialog can pick a bundled preview asset', (tester) async {
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
    await tester.pump();
    await tester.tap(find.byKey(const Key('exercise-media-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deadlift'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ).first,
      'heavy deadlift',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    final stored = await db(tester, plans.all);
    final block = stored.single.days.single.blocks.single;
    expect(block.mediaUri, 'assets/image/exercises/deadlift.svg');
    expect(block.mediaSource, ExerciseMediaSource.asset);
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

    Finder dialogField() => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );

    await tester.tap(find.text('Add exercise'));
    await tester.pump();
    await tester.enterText(dialogField().first, 'bench press');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'second exercise name'),
      'bent over row',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('3 × 12 bench press + 3 × 12 bent over row'),
      ),
      findsOneWidget,
    );

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

    Finder dialogField() => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );

    await tester.tap(find.text('Add exercise'));
    await tester.pump();
    await tester.enterText(dialogField().first, 'bench press');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'second exercise name'),
      'bent over row',
    );
    await tester.ensureVisible(find.byKey(const Key('add-movement')));
    await tester.tap(find.byKey(const Key('add-movement')));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'exercise 3 name'),
      'face pull',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text(
          '3 × 12 bench press + 3 × 12 bent over row + 3 × 12 face pull',
        ),
      ),
      findsOneWidget,
    );

    final stored = await db(tester, plans.all);
    final block = stored.single.days.single.blocks.single;
    expect(block.kind, BlockKind.superset);
    expect(
      block.exercises.map((item) => item.title).toList(),
      ['bench press', 'bent over row', 'face pull'],
    );
  });

  testWidgets('a plan can gain a common section with a duration exercise',
      (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));
    await launch(tester, AppRoutes.home);

    await tester.tap(find.text('Push week'));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Add section'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      'abs',
    );
    await tester.tap(find.text('Save section'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.editSection);
    expect(find.text('abs'), findsWidgets);

    Finder dialogField() => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        );

    await tester.tap(find.text('Add exercise'));
    await tester.pump();
    await tester.enterText(dialogField().first, 'shoot out');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Duration').first);
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextFormField, 'seconds'),
      ),
      '30',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pump();
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(DayEditorPage),
        matching: find.text('3 × 30s shoot out'),
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.plan);
    expect(find.text('abs'), findsWidgets);

    final stored = await db(tester, plans.all);
    expect(stored.single.commonSections, hasLength(1));
    expect(stored.single.commonSections.single.title, 'abs');
    expect(
      stored.single.commonSections.single.blocks.single.exercises.single.title,
      'shoot out',
    );
    expect(
      stored.single.commonSections.single.blocks.single.exercises.single
          .prescribedDurationSeconds,
      30,
    );
  });
}
