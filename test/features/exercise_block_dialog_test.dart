import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/exercise_block_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(800, 1400);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.resetPhysicalSize();
  });
  testWidgets('catalog match fills target areas on a single exercise',
      (tester) async {
    ExerciseBlock? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                saved = await showExerciseBlockDialog(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('exercise-name-0')),
      'bench press',
    );
    await tester.pump();

    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-triceps')), findsOneWidget);
    expect(find.byKey(const Key('target-front-shoulders')), findsOneWidget);

    await tester.tap(find.text('Save exercise'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(
      saved!.exercises.single.targetAreaIds,
      ['chest', 'triceps', 'front-shoulders'],
    );
    expect(saved!.kind, BlockKind.single);
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
                saved = await showExerciseBlockDialog(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Superset'));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('exercise-name-0')),
      'bench press',
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('exercise-name-1')), 'rdl');
    await tester.pump();

    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-hamstrings')), findsOneWidget);
    expect(find.byKey(const Key('target-glutes')), findsOneWidget);

    await tester.tap(find.text('Save exercise'));
    await tester.pump();

    expect(saved!.kind, BlockKind.superset);
    expect(saved!.exercises, hasLength(2));
    expect(
      saved!.exercises[0].targetAreaIds,
      ['chest', 'triceps', 'front-shoulders'],
    );
    expect(saved!.exercises[1].targetAreaIds, ['glutes', 'hamstrings']);
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
                saved = await showExerciseBlockDialog(
                  context,
                  existing: existing,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-triceps')), findsNothing);

    await tester.enterText(find.byKey(const Key('exercise-sets')), '5');
    await tester.pump();
    expect(find.byKey(const Key('target-chest')), findsOneWidget);
    expect(find.byKey(const Key('target-triceps')), findsNothing);

    await tester.enterText(find.byKey(const Key('exercise-name-0')), 'rdl');
    await tester.tap(find.text('Save exercise'));
    await tester.pump();

    expect(find.text('Replace target areas?'), findsOneWidget);
    await tester.tap(find.text('Keep mine'));
    await tester.pump();

    expect(saved!.exercises.single.title, 'rdl');
    expect(saved!.exercises.single.targetAreaIds, ['chest']);
    expect(saved!.exercises.single.prescribedSets, 5);
  });
}
