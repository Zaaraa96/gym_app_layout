import '../common/exercise_asset_catalog.dart';
import 'models/catalog_exercise.dart';
import 'models/enums.dart';
import 'plan_catalog.dart';

class CatalogWriteException implements Exception {
  CatalogWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Shared checks for a user-created catalog row before it is persisted.
void validateUserCatalogExercise({
  required CatalogExercise exercise,
  required Iterable<CatalogExercise> existing,
}) {
  final title = exercise.title.trim();
  if (title.isEmpty) {
    throw CatalogWriteException('Add a name before saving.');
  }
  if (!exercise.hasPicture) {
    throw CatalogWriteException('Add a picture before saving.');
  }
  if (canonicalizeTargetAreaIds(exercise.targetAreaIds).isEmpty) {
    throw CatalogWriteException('Add at least one target area.');
  }
  if (exercise.defaultSets < 1) {
    throw CatalogWriteException('Sets must be at least 1.');
  }
  if (exercise.prescriptionType == PrescriptionType.reps) {
    if (exercise.defaultReps == null || exercise.defaultReps! < 1) {
      throw CatalogWriteException('Reps must be at least 1.');
    }
  } else if (exercise.defaultDurationSeconds == null ||
      exercise.defaultDurationSeconds! < 1) {
    throw CatalogWriteException('Duration must be at least 1 second.');
  }

  final key = normalizeExerciseTitle(title);
  for (final other in existing) {
    if (other.id == exercise.id) continue;
    if (normalizeExerciseTitle(other.title) == key) {
      throw CatalogWriteException(
        'An exercise named ${other.title} already exists.',
      );
    }
  }
}

CatalogExercise prepareUserCatalogExercise(CatalogExercise exercise) {
  final targets = canonicalizeTargetAreaIds(exercise.targetAreaIds);
  final regions = canonicalizeRegionIds(
    exercise.regionIds.isEmpty ? defaultRegionIdsFor(targets) : exercise.regionIds,
  );
  final timed = exercise.prescriptionType == PrescriptionType.timed;
  return CatalogExercise(
    id: exercise.id,
    localId: exercise.localId,
    title: exercise.title.trim(),
    aliases: [
      for (final alias in exercise.aliases)
        if (normalizeExerciseTitle(alias).isNotEmpty) alias.trim(),
    ],
    regionIds: regions,
    targetAreaIds: targets,
    mediaUri: exercise.mediaUri.trim(),
    mediaSource: exercise.mediaSource,
    mediaKind: exercise.mediaKind,
    gifPath: exercise.gifPath,
    origin: CatalogOrigin.user,
    prescriptionType: exercise.prescriptionType,
    defaultSets: exercise.defaultSets,
    defaultReps: timed ? null : exercise.defaultReps,
    defaultDurationSeconds: timed ? exercise.defaultDurationSeconds : null,
    createdAt: exercise.createdAt,
    updatedAt: DateTime.now().toUtc(),
  );
}

CatalogExercise copyUserCatalogExercise(
  CatalogExercise source, {
  String? id,
}) {
  return CatalogExercise(
    id: id ?? source.id,
    localId: source.localId,
    title: source.title,
    aliases: [...source.aliases],
    regionIds: [...source.regionIds],
    targetAreaIds: [...source.targetAreaIds],
    mediaUri: source.mediaUri,
    mediaSource: source.mediaSource,
    mediaKind: source.mediaKind,
    gifPath: source.gifPath,
    origin: CatalogOrigin.user,
    prescriptionType: source.prescriptionType,
    defaultSets: source.defaultSets,
    defaultReps: source.defaultReps,
    defaultDurationSeconds: source.defaultDurationSeconds,
    createdAt: source.createdAt,
    updatedAt: source.updatedAt,
  );
}
