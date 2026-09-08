import 'package:isar/isar.dart';

import '../../domain/models/enums.dart';
import '../../domain/new_id.dart';

part 'user_catalog_exercise.g.dart';

/// User-created catalog movement. Bundled stills live in Dart, not here.
@collection
class UserCatalogExercise {
  Id id = Isar.autoIncrement;

  @Index()
  late String uuid;

  late String title;

  List<String> aliases = [];

  List<String> regionIds = [];

  List<String> targetAreaIds = [];

  late String mediaUri;

  @enumerated
  ExerciseMediaSource mediaSource = ExerciseMediaSource.none;

  @enumerated
  ExerciseMediaKind mediaKind = ExerciseMediaKind.unknown;

  @enumerated
  PrescriptionType prescriptionType = PrescriptionType.reps;

  late int defaultSets;

  int? defaultReps;

  int? defaultDurationSeconds;

  late DateTime createdAt;

  late DateTime updatedAt;

  UserCatalogExercise();

  UserCatalogExercise.create({
    String? uuid,
    required this.title,
    List<String>? aliases,
    List<String>? regionIds,
    List<String>? targetAreaIds,
    required this.mediaUri,
    this.mediaSource = ExerciseMediaSource.asset,
    this.mediaKind = ExerciseMediaKind.image,
    this.prescriptionType = PrescriptionType.reps,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultDurationSeconds,
    required this.createdAt,
    required this.updatedAt,
  })  : uuid = uuid ?? newUuid(),
        aliases = aliases ?? [],
        regionIds = regionIds ?? [],
        targetAreaIds = targetAreaIds ?? [];
}
