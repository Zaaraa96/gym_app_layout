import '../new_id.dart';
import 'enums.dart';

/// Local adapter key. `0` means the row is not persisted yet.
/// Product identity is [WorkoutPlan.uuid], not this field.
const int unassignedLocalId = 0;

/// Prescribed program. Edits here must not rewrite past sessions.
class WorkoutPlan {
  /// Local row key assigned by a repository. Not the identity sent to a remote API.
  int id = unassignedLocalId;

  /// Stable identity for sync and for session `planId`.
  late String uuid;

  /// True when a local write has not been acknowledged by sync.
  bool dirty = true;

  late String title;

  late PlanSource source;

  late DateTime createdAt;

  late DateTime updatedAt;

  /// `basic-plan` days, in display order.
  List<PlanDay> days = [];

  /// Named extra sections (`common-plan`) chosen per session, not a second plan.
  List<CommonSection> commonSections = [];

  WorkoutPlan();

  WorkoutPlan.create({
    String? uuid,
    this.dirty = true,
    required this.title,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    List<PlanDay>? days,
    List<CommonSection>? commonSections,
  })  : uuid = uuid ?? newUuid(),
        days = days ?? [],
        commonSections = commonSections ?? [];
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

  /// Legacy bundled SVG path. Prefer [mediaUri] for new data.
  String? svgPath;

  /// Asset path, local file path, or remote URL depending on [mediaSource].
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

  ExercisePrescription();

  ExercisePrescription.create({
    required this.prescriptionId,
    required this.title,
    required this.prescribedSets,
    this.prescribedReps,
    this.prescribedDurationSeconds,
    this.targetWeightKg,
  });
}
