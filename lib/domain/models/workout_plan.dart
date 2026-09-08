import '../new_id.dart';
import 'enums.dart';

/// Local adapter key. `0` means the row is not persisted yet.
/// Product identity is [WorkoutPlan.uuid], not this field.
const int unassignedLocalId = 0;

/// Fallback list title while the builder name field is still empty.
const untitledPlanTitle = 'Untitled plan';

/// Prescribed program. Edits here must not rewrite past sessions.
class WorkoutPlan {
  /// Local row key assigned by a repository. Not the identity sent to a remote API.
  int id = unassignedLocalId;

  /// Stable identity for sync and for session `planId`.
  late String uuid;

  /// True when a local write has not been acknowledged by sync.
  bool dirty = true;

  late String title;

  /// Optional plan copy. Never required for activation.
  String description = '';

  /// Stable [planGoals] ids. Advisory for suggestions and Review guidance.
  List<String> goalIds = [];

  late PlanSource source;

  /// Drafts stay in the builder; only [PlanStatus.active] can start a workout.
  PlanStatus status = PlanStatus.active;

  late DateTime createdAt;

  late DateTime updatedAt;

  /// `basic-plan` days, in display order.
  List<PlanDay> days = [];

  WorkoutPlan();

  WorkoutPlan.create({
    String? uuid,
    this.dirty = true,
    required this.title,
    this.description = '',
    List<String>? goalIds,
    required this.source,
    this.status = PlanStatus.active,
    required this.createdAt,
    required this.updatedAt,
    List<PlanDay>? days,
  })  : uuid = uuid ?? newUuid(),
        goalIds = goalIds ?? [],
        days = days ?? [];

  /// List and app-bar title. Empty names stay invalid in the builder.
  String get displayTitle {
    final trimmed = title.trim();
    return trimmed.isEmpty ? untitledPlanTitle : trimmed;
  }

  bool get isDraft => status == PlanStatus.draft;
}

class PlanDay {
  late String dayId;
  late String title;
  late String summary;
  List<ExerciseBlock> blocks = [];

  PlanDay();

  PlanDay.create({
    required this.dayId,
    required this.title,
    this.summary = '',
    List<ExerciseBlock>? blocks,
  }) : blocks = blocks ?? [];
}

/// Legacy extra section from v1 `common-plan`. Converted to a [PlanDay] on
/// read/import. Not stored on [WorkoutPlan].
class CommonSection {
  late String sectionId;
  late String title;
  List<ExerciseBlock> blocks = [];

  CommonSection();

  CommonSection.create({
    required this.sectionId,
    required this.title,
    List<ExerciseBlock>? blocks,
  }) : blocks = blocks ?? [];
}

class ExerciseBlock {
  late String blockId;

  late BlockKind kind;

  /// Legacy block media. New writes leave these empty; prefer exercise media.
  String? svgPath;

  /// Legacy block media. Readers fall back here when exercise media is absent.
  String? mediaUri;

  ExerciseMediaSource mediaSource = ExerciseMediaSource.none;

  ExerciseMediaKind mediaKind = ExerciseMediaKind.unknown;

  /// One item for [BlockKind.single]; two or more for [BlockKind.superset].
  List<ExercisePrescription> exercises = [];

  ExerciseBlock();

  ExerciseBlock.create({
    required this.blockId,
    required this.kind,
    this.svgPath,
    this.mediaUri,
    this.mediaSource = ExerciseMediaSource.none,
    this.mediaKind = ExerciseMediaKind.unknown,
    List<ExercisePrescription>? exercises,
  }) : exercises = exercises ?? [];
}

class ExercisePrescription {
  late String prescriptionId;
  late String title;

  /// Always >= 1.
  late int prescribedSets;

  /// JSON `times`. Exactly one of this or [prescribedDurationSeconds] is non-null.
  int? prescribedReps;

  /// JSON `duration`. Chooses the live-workout duration timer when set.
  int? prescribedDurationSeconds;

  /// Unused in v1 UI; store null.
  double? targetWeightKg;

  /// Stable target-area ids. Optional; never blocks plan creation.
  List<String> targetAreaIds = [];

  /// Bundled catalog id when this title was chosen from the catalog.
  String? catalogExerciseId;

  /// Bundled SVG/PNG path. Prefer [mediaUri] for new data.
  String? svgPath;

  /// Asset path, local file path, or remote URL depending on [mediaSource].
  String? mediaUri;

  ExerciseMediaSource mediaSource = ExerciseMediaSource.none;

  ExerciseMediaKind mediaKind = ExerciseMediaKind.unknown;

  ExercisePrescription();

  ExercisePrescription.create({
    required this.prescriptionId,
    required this.title,
    required this.prescribedSets,
    this.prescribedReps,
    this.prescribedDurationSeconds,
    this.targetWeightKg,
    List<String>? targetAreaIds,
    this.catalogExerciseId,
    this.svgPath,
    this.mediaUri,
    this.mediaSource = ExerciseMediaSource.none,
    this.mediaKind = ExerciseMediaKind.unknown,
  }) : targetAreaIds = targetAreaIds ?? [];

  bool get hasStoredMedia {
    final uri = mediaUri?.trim();
    return uri != null &&
        uri.isNotEmpty &&
        mediaSource != ExerciseMediaSource.none &&
        mediaKind != ExerciseMediaKind.unknown;
  }
}
