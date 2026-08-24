import 'package:isar/isar.dart';

import 'enums.dart';

part 'workout_plan.g.dart';

/// Prescribed program. Edits here must not rewrite past [WorkoutSession]s.
@collection
class WorkoutPlan {
  Id id = Isar.autoIncrement;

  late String title;

  @enumerated
  late PlanSource source;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  /// `basic-plan` days, in display order.
  List<PlanDay> days = [];

  /// Named extra sections (`common-plan`) chosen per session, not a second plan.
  List<CommonSection> commonSections = [];

  WorkoutPlan();

  WorkoutPlan.create({
    required this.title,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    List<PlanDay>? days,
    List<CommonSection>? commonSections,
  })  : days = days ?? [],
        commonSections = commonSections ?? [];
}

@embedded
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

@embedded
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

@embedded
class ExerciseBlock {
  late String blockId;

  @enumerated
  late BlockKind kind;

  /// Optional icon asset; may be empty on import.
  String? svgPath;

  /// One item for [BlockKind.single]; two or more for [BlockKind.superset].
  List<ExercisePrescription> exercises = [];

  ExerciseBlock();

  ExerciseBlock.create({
    required this.blockId,
    required this.kind,
    this.svgPath,
    List<ExercisePrescription>? exercises,
  }) : exercises = exercises ?? [];
}

@embedded
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
