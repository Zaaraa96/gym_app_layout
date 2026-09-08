import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/exercise_editor_page.dart';

import '../helpers/exercise_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(800, 1400);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
  });

  Future<ExerciseBlock?> openEditor(
    WidgetTester tester, {
    ExerciseBlock? existing,
    List<String> goalIds = const [],
  }) async {
    ExerciseBlock? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showExerciseEditor(
                  context,
                  existing: existing,
                  goalIds: goalIds,
                  dayLabel: 'Day 1 · Push',
                );
                if (result is ExerciseEditorSaved) saved = result.block;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return Future.value(saved).then((_) => saved);
  }

  testWidgets('catalog match fills target areas on a single exercise',
      (tester) async {
    ExerciseBlock? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showExerciseEditor(context);
                if (result is ExerciseEditorSaved) saved = result.block;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(exerciseNameField(), 'bench press');
    await tester.pump();

    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-triceps')), findsOneWidget);
    expect(find.byKey(const Key('target-front-shoulders')), findsOneWidget);

    await commitExerciseEditor(tester);

    expect(saved, isNotNull);
    expect(
      saved!.exercises.single.targetAreaIds,
      ['chest', 'triceps', 'front-shoulders'],
    );
    expect(saved!.kind, BlockKind.single);
    expect(saved!.exercises.single.mediaUri, contains('bench-press'));
    expect(saved!.svgPath, isNull);
  });

  testWidgets('each movement in a superset keeps its own target areas',
      (tester) async {
    ExerciseBlock? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showExerciseEditor(context);
                if (result is ExerciseEditorSaved) saved = result.block;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await selectSuperset(tester);

    await tester.enterText(exerciseNameField(), 'bench press');
    await tester.pump();
    await tester.enterText(exerciseNameField(1), 'rdl');
    await tester.pump();

    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-hamstrings')), findsOneWidget);
    expect(find.byKey(const Key('target-glutes')), findsOneWidget);

    await commitExerciseEditor(tester);

    expect(saved!.kind, BlockKind.superset);
    expect(saved!.exercises, hasLength(2));
    expect(
      saved!.exercises[0].targetAreaIds,
      ['chest', 'triceps', 'front-shoulders'],
    );
    expect(saved!.exercises[1].targetAreaIds, ['glutes', 'hamstrings']);
    expect(saved!.exercises.map((item) => item.prescribedSets), [3, 3]);
  });

  testWidgets('manual target edits survive set changes and ask before replace',
      (tester) async {
    ExerciseBlock? saved;
    final existing = ExerciseBlock.create(
      blockId: 'b1',
      kind: BlockKind.single,
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'p1',
          title: 'bench press',
          prescribedSets: 4,
          prescribedReps: 8,
          targetAreaIds: const ['chest'],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showExerciseEditor(
                  context,
                  existing: existing,
                );
                if (result is ExerciseEditorSaved) saved = result.block;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-triceps')), findsNothing);

    await tester.enterText(exerciseSetsField(), '5');
    await tester.pump();
    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-triceps')), findsNothing);

    await tester.enterText(exerciseNameField(), 'rdl');
    await commitExerciseEditor(tester);

    expect(find.text('Replace target areas?'), findsOneWidget);
    await tester.tap(find.text('Keep mine'));
    await tester.pumpAndSettle();

    expect(saved!.exercises.single.title, 'rdl');
    expect(saved!.exercises.single.targetAreaIds, ['chest']);
    expect(saved!.exercises.single.prescribedSets, 5);
  });

  testWidgets('dirty close asks before discarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showExerciseEditor(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(exerciseNameField(), 'ghost squat');
    await tester.pump();
    await tester.tap(find.byTooltip('Close exercise editor'));
    await tester.pumpAndSettle();
    expect(find.text('Discard exercise changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseEditorPage), findsOneWidget);
    await tester.tap(find.byTooltip('Close exercise editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseEditorPage), findsNothing);
  });

  testWidgets('empty name keeps the editor open', (tester) async {
    await openEditor(tester);
    await commitExerciseEditor(tester);
    expect(find.textContaining('Add a name for Movement A'), findsOneWidget);
    expect(find.byType(ExerciseEditorPage), findsOneWidget);
  });
}
