import 'models/models.dart';

/// Moves leftover block-level media onto exercises.
///
/// Single blocks copy onto the only exercise. Supersets copy onto Movement A.
/// Suggestions are not invented here; catalog matching belongs to the editor.
ExerciseBlock migrateBlockMediaToExercises(ExerciseBlock block) {
  if (block.exercises.isEmpty) return _clearedBlockMedia(block);
  final exercises = [
    for (var i = 0; i < block.exercises.length; i++)
      _exerciseWithLegacyMedia(
        block.exercises[i],
        block,
        takeLegacy: i == 0,
      ),
  ];
  return ExerciseBlock.create(
    blockId: block.blockId,
    kind: block.kind,
    exercises: exercises,
  );
}

ExercisePrescription _exerciseWithLegacyMedia(
  ExercisePrescription exercise,
  ExerciseBlock block, {
  required bool takeLegacy,
}) {
  if (exercise.hasStoredMedia || _hasLegacySvg(exercise)) {
    return exercise;
  }
  if (!takeLegacy || !_blockHasLegacyMedia(block)) return exercise;
  return ExercisePrescription.create(
    prescriptionId: exercise.prescriptionId,
    title: exercise.title,
    prescribedSets: exercise.prescribedSets,
    prescribedReps: exercise.prescribedReps,
    prescribedDurationSeconds: exercise.prescribedDurationSeconds,
    targetWeightKg: exercise.targetWeightKg,
    targetAreaIds: List<String>.from(exercise.targetAreaIds),
    catalogExerciseId: exercise.catalogExerciseId,
    svgPath: block.svgPath,
    mediaUri: block.mediaUri ?? block.svgPath,
    mediaSource: _legacySource(block),
    mediaKind: _legacyKind(block),
  );
}

ExerciseBlock _clearedBlockMedia(ExerciseBlock block) {
  return ExerciseBlock.create(
    blockId: block.blockId,
    kind: block.kind,
    exercises: block.exercises,
  );
}

bool _hasLegacySvg(ExercisePrescription exercise) {
  final path = exercise.svgPath?.trim();
  return path != null && path.isNotEmpty;
}

bool _blockHasLegacyMedia(ExerciseBlock block) {
  final uri = block.mediaUri?.trim();
  if (uri != null &&
      uri.isNotEmpty &&
      block.mediaSource != ExerciseMediaSource.none) {
    return true;
  }
  final legacy = block.svgPath?.trim();
  return legacy != null && legacy.isNotEmpty;
}

ExerciseMediaSource _legacySource(ExerciseBlock block) {
  if (block.mediaSource != ExerciseMediaSource.none) return block.mediaSource;
  return ExerciseMediaSource.asset;
}

ExerciseMediaKind _legacyKind(ExerciseBlock block) {
  if (block.mediaKind != ExerciseMediaKind.unknown) return block.mediaKind;
  final path = (block.mediaUri ?? block.svgPath ?? '').toLowerCase();
  if (path.endsWith('.svg')) return ExerciseMediaKind.svg;
  if (path.endsWith('.gif')) return ExerciseMediaKind.gif;
  if (path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.webm')) {
    return ExerciseMediaKind.video;
  }
  if (path.isEmpty) return ExerciseMediaKind.unknown;
  return ExerciseMediaKind.image;
}
