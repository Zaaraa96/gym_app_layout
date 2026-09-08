import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';
import 'package:gym_app/domain/exercise_editor_draft.dart';
import 'package:gym_app/domain/exercise_media_migration.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/new_id.dart';

void main() {
  var n = 0;
  String nextId() => 'id-${n++}';

  ExercisePrescription squat({
    int sets = 3,
    int reps = 12,
    List<String> targets = const ['quads', 'glutes'],
  }) {
    return ExercisePrescription.create(
      prescriptionId: 'p-squat',
      title: 'squat',
      prescribedSets: sets,
      prescribedReps: reps,
      targetAreaIds: targets,
    );
  }

  test('new single draft is invalid until it has a name', () {
    final draft = ExerciseBlockDraft.createNew();
    expect(draft.mode, ExerciseEditorMode.single);
    expect(draft.canCommit, isFalse);
    expect(draft.validate().first.message, contains('Movement A'));
    draft.movements.first.title = 'Custom raise';
    expect(draft.canCommit, isTrue);
    final block = draft.toBlock(newId: nextId);
    expect(block.kind, BlockKind.single);
    expect(block.exercises.single.title, 'Custom raise');
    expect(block.exercises.single.catalogExerciseId, isNull);
    expect(block.svgPath, isNull);
    expect(block.mediaUri, isNull);
  });

  test('single catalog match stores id, targets, and media on the exercise', () {
    final draft = ExerciseBlockDraft.createNew();
    draft.movements.first.setTitle('bench press');
    expect(draft.canCommit, isTrue);
    final block = draft.toBlock(newId: nextId);
    final exercise = block.exercises.single;
    expect(exercise.catalogExerciseId, 'bench-press');
    expect(exercise.targetAreaIds, ['chest', 'triceps', 'front-shoulders']);
    expect(exercise.mediaUri, 'assets/image/exercises/bench-press.png');
    expect(exercise.mediaSource, ExerciseMediaSource.asset);
    expect(block.mediaUri, isNull);
  });

  test('timed prescription persists duration and clears reps', () {
    final draft = ExerciseBlockDraft.createNew();
    draft.movements.first
      ..title = 'plank'
      ..type = PrescriptionType.timed
      ..durationSeconds = 45
      ..sets = 2;
    final block = draft.toBlock(newId: nextId);
    expect(block.exercises.single.prescribedDurationSeconds, 45);
    expect(block.exercises.single.prescribedReps, isNull);
    expect(block.exercises.single.prescribedSets, 2);
  });

  test('single to superset keeps Movement A and shared rounds', () {
    final draft = ExerciseBlockDraft.createNew();
    draft.movements.first
      ..title = 'bench press'
      ..sets = 4
      ..reps = 8;
    draft.switchToSuperset();
    expect(draft.mode, ExerciseEditorMode.superset);
    expect(draft.rounds, 4);
    expect(draft.movements, hasLength(2));
    expect(draft.movements.first.title, 'bench press');
    expect(draft.movements.last.isBlank, isTrue);
    expect(draft.canCommit, isFalse);
    draft.movements.last.title = 'rdl';
    final block = draft.toBlock(newId: nextId);
    expect(block.kind, BlockKind.superset);
    expect(block.exercises.map((item) => item.prescribedSets), [4, 4]);
    expect(block.exercises[1].title, 'rdl');
  });

  test('superset to single without extra data needs no confirmation', () {
    final draft = ExerciseBlockDraft.createNew()..switchToSuperset();
    draft.movements.first.title = 'bench press';
    expect(draft.switchToSingle(), isTrue);
    expect(draft.mode, ExerciseEditorMode.single);
    expect(draft.movements, hasLength(1));
    expect(draft.movements.first.title, 'bench press');
  });

  test('superset to single with extra data requires confirmation', () {
    final draft = ExerciseBlockDraft.createNew()..switchToSuperset();
    draft.movements.first.title = 'bench press';
    draft.movements.last.title = 'rdl';
    expect(draft.switchToSingle(), isFalse);
    expect(draft.mode, ExerciseEditorMode.superset);
    expect(draft.switchToSingle(confirmed: true), isTrue);
    expect(draft.mode, ExerciseEditorMode.single);
    expect(draft.movements.single.title, 'bench press');
  });

  test('cannot remove the last two superset movements', () {
    final draft = ExerciseBlockDraft.createNew()..switchToSuperset();
    draft.movements.first.title = 'a';
    draft.movements.last.title = 'b';
    expect(draft.removeMovement(1), isFalse);
    draft.addMovement();
    draft.movements.last.title = 'c';
    expect(draft.removeMovement(2), isTrue);
    expect(draft.movements, hasLength(2));
    expect(draft.mode, ExerciseEditorMode.superset);
  });

  test('legacy unequal set counts require explicit rounds', () {
    final block = ExerciseBlock.create(
      blockId: 'ss',
      kind: BlockKind.superset,
      exercises: [
        squat(sets: 3),
        ExercisePrescription.create(
          prescriptionId: 'p-rdl',
          title: 'rdl',
          prescribedSets: 5,
          prescribedReps: 8,
        ),
      ],
    );
    final draft = ExerciseBlockDraft.fromBlock(block);
    expect(draft.unequalRounds, isTrue);
    expect(draft.rounds, isNull);
    expect(draft.canCommit, isFalse);
    expect(draft.validate().first.message, contains('different set counts'));
    draft.setRounds(4);
    draft.movements[1].title = 'rdl';
    final saved = draft.toBlock(newId: nextId);
    expect(saved.exercises.map((item) => item.prescribedSets), [4, 4]);
  });

  test('manual targets survive catalog title changes until confirmed', () {
    final draft = ExerciseBlockDraft.fromBlock(
      ExerciseBlock.create(
        blockId: 'b1',
        kind: BlockKind.single,
        exercises: [squat(targets: const ['chest'])],
      ),
    );
    expect(draft.movements.first.manualTargets, isTrue);
    final pending = draft.movements.first.setTitle('rdl');
    expect(pending?.id, 'romanian-deadlift');
    expect(draft.movements.first.targetAreaIds, ['chest']);
    draft.movements.first.applyCatalog(pending!, replaceManual: true);
    expect(draft.movements.first.targetAreaIds, ['glutes', 'hamstrings']);
    expect(draft.movements.first.manualTargets, isFalse);
  });

  test('migrateBlockMediaToExercises copies leftover media onto Movement A', () {
    final single = migrateBlockMediaToExercises(
      ExerciseBlock.create(
        blockId: 'b1',
        kind: BlockKind.single,
        svgPath: 'assets/image/exercises/squat.png',
        mediaUri: 'assets/image/exercises/squat.png',
        mediaSource: ExerciseMediaSource.asset,
        mediaKind: ExerciseMediaKind.image,
        exercises: [squat()],
      ),
    );
    expect(single.svgPath, isNull);
    expect(single.exercises.single.mediaUri, 'assets/image/exercises/squat.png');
    expect(single.exercises.single.mediaSource, ExerciseMediaSource.asset);

    final superset = migrateBlockMediaToExercises(
      ExerciseBlock.create(
        blockId: 'ss',
        kind: BlockKind.superset,
        mediaUri: 'assets/image/exercises/bench-press.png',
        mediaSource: ExerciseMediaSource.asset,
        mediaKind: ExerciseMediaKind.image,
        exercises: [
          squat(),
          ExercisePrescription.create(
            prescriptionId: 'p2',
            title: 'rdl',
            prescribedSets: 3,
            prescribedReps: 10,
          ),
        ],
      ),
    );
    expect(superset.exercises.first.mediaUri, 'assets/image/exercises/bench-press.png');
    expect(superset.exercises.last.mediaUri, isNull);
  });

  test('editing preserves block and prescription ids', () {
    final original = ExerciseBlock.create(
      blockId: 'keep-block',
      kind: BlockKind.single,
      exercises: [squat()],
    );
    final draft = ExerciseBlockDraft.fromBlock(original);
    draft.movements.first.title = 'front squat';
    final saved = draft.toBlock(newId: newId);
    expect(saved.blockId, 'keep-block');
    expect(saved.exercises.single.prescriptionId, 'p-squat');
  });

  test('searchExerciseCatalog ranks exact names ahead of goal matches', () {
    final results = searchExerciseCatalog(
      query: 'plank',
      goalIds: const ['build-muscle'],
    );
    expect(results.first.id, 'plank');
    final empty = searchExerciseCatalog(
      query: '',
      goalIds: const ['build-muscle'],
    );
    expect(empty, isNotEmpty);
    expect(empty.first.goalIds, contains('build-muscle'));
  });
}
