import '../plan_catalog.dart';
import 'enums.dart';
import 'workout_plan.dart';

/// One movement in the merged catalog (bundled still/GIF or a user-added row).
class CatalogExercise {
  CatalogExercise({
    required this.id,
    this.localId = unassignedLocalId,
    required this.title,
    List<String>? aliases,
    List<String>? regionIds,
    List<String>? targetAreaIds,
    required this.mediaUri,
    this.mediaSource = ExerciseMediaSource.asset,
    this.mediaKind = ExerciseMediaKind.image,
    this.gifPath,
    this.origin = CatalogOrigin.bundled,
    this.prescriptionType = PrescriptionType.reps,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultDurationSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : aliases = aliases ?? const [],
        targetAreaIds = canonicalizeTargetAreaIds(targetAreaIds ?? const []),
        regionIds = canonicalizeRegionIds(
          regionIds ?? defaultRegionIdsFor(targetAreaIds ?? const []),
        ),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  /// Bundled slug (`plank`) or user UUID.
  final String id;

  /// Local Isar/memory row key. Unused for bundled entries.
  int localId;

  String title;
  List<String> aliases;
  List<String> regionIds;
  List<String> targetAreaIds;

  /// Still image. Required for a movement to appear in the supported list.
  String mediaUri;
  ExerciseMediaSource mediaSource;
  ExerciseMediaKind mediaKind;

  /// Looping form demo. Bundled only.
  String? gifPath;

  CatalogOrigin origin;

  PrescriptionType prescriptionType;
  int defaultSets;
  int? defaultReps;
  int? defaultDurationSeconds;

  DateTime createdAt;
  DateTime updatedAt;

  bool get isBundled => origin == CatalogOrigin.bundled;
  bool get isUserCreated => origin == CatalogOrigin.user;
  bool get hasPicture =>
      mediaUri.trim().isNotEmpty && mediaSource != ExerciseMediaSource.none;

  bool get hasGif {
    final path = gifPath?.trim();
    return path != null && path.isNotEmpty;
  }
}
