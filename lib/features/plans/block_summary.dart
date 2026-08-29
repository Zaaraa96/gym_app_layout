import '../../data/models/workout_plan.dart';

export 'exercise_media.dart';

/// Sets badge for a block. Prescriptions in one block share the set count.
int blockSetCount(ExerciseBlock block) =>
    block.exercises.isEmpty ? 0 : block.exercises.first.prescribedSets;

/// Compact load next to a title: `x12` or `x30s`.
String formatLoad(ExercisePrescription prescription) {
  if (prescription.prescribedDurationSeconds != null) {
    return 'x${prescription.prescribedDurationSeconds}s';
  }
  return 'x${prescription.prescribedReps ?? 0}';
}

String formatPrescription(ExercisePrescription prescription) {
  final load = prescription.prescribedDurationSeconds != null
      ? '${prescription.prescribedSets} × ${prescription.prescribedDurationSeconds}s'
      : '${prescription.prescribedSets} × ${prescription.prescribedReps ?? 0}';
  return '$load ${prescription.title}';
}

String formatBlock(ExerciseBlock block) =>
    block.exercises.map(formatPrescription).join(' + ');
