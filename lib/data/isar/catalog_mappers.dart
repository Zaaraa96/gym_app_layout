import '../../domain/models/catalog_exercise.dart';
import '../../domain/models/enums.dart';
import 'user_catalog_exercise.dart';

CatalogExercise catalogExerciseFromIsar(UserCatalogExercise row) {
  return CatalogExercise(
    id: row.uuid,
    localId: row.id,
    title: row.title,
    aliases: [...row.aliases],
    regionIds: [...row.regionIds],
    targetAreaIds: [...row.targetAreaIds],
    mediaUri: row.mediaUri,
    mediaSource: row.mediaSource,
    mediaKind: row.mediaKind,
    origin: CatalogOrigin.user,
    prescriptionType: row.prescriptionType,
    defaultSets: row.defaultSets,
    defaultReps: row.defaultReps,
    defaultDurationSeconds: row.defaultDurationSeconds,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

UserCatalogExercise catalogExerciseToIsar(CatalogExercise exercise) {
  final row = UserCatalogExercise()
    ..uuid = exercise.id
    ..title = exercise.title
    ..aliases = [...exercise.aliases]
    ..regionIds = [...exercise.regionIds]
    ..targetAreaIds = [...exercise.targetAreaIds]
    ..mediaUri = exercise.mediaUri
    ..mediaSource = exercise.mediaSource
    ..mediaKind = exercise.mediaKind
    ..prescriptionType = exercise.prescriptionType
    ..defaultSets = exercise.defaultSets
    ..defaultReps = exercise.defaultReps
    ..defaultDurationSeconds = exercise.defaultDurationSeconds
    ..createdAt = exercise.createdAt
    ..updatedAt = exercise.updatedAt;
  if (exercise.localId > 0) {
    row.id = exercise.localId;
  }
  return row;
}
