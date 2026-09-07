import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder exerciseNameField([int index = 0]) =>
    find.byKey(Key('exercise-name-$index'));

Finder exerciseEditorCommit() =>
    find.byKey(const Key('exercise-editor-commit'));

Finder exerciseSetsField() => find.byKey(const Key('exercise-sets'));

Finder exerciseRepsField([int index = 0]) =>
    find.byKey(Key('exercise-reps-$index'));

Finder exerciseDurationField([int index = 0]) =>
    find.byKey(Key('exercise-duration-$index'));

Future<void> openAddExercise(WidgetTester tester) async {
  await tester.tap(find.text('Add exercise'));
  await tester.pumpAndSettle();
}

Future<void> commitExerciseEditor(WidgetTester tester) async {
  final commit = exerciseEditorCommit();
  await tester.ensureVisible(commit);
  await tester.tap(commit);
  await tester.pumpAndSettle();
}

Future<void> selectSuperset(WidgetTester tester) async {
  await tester.tap(find.text('Superset'));
  await tester.pumpAndSettle();
}

Future<void> selectTimed(WidgetTester tester) async {
  await tester.tap(find.text('Timed'));
  await tester.pumpAndSettle();
}
