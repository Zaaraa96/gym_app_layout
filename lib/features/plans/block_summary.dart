import '../../data/models/workout_plan.dart';

String formatPrescription(ExercisePrescription prescription) {
  final load = prescription.prescribedDurationSeconds != null
      ? '${prescription.prescribedSets} × ${prescription.prescribedDurationSeconds}s'
      : '${prescription.prescribedSets} × ${prescription.prescribedReps ?? 0}';
  return '$load ${prescription.title}';
}

String formatBlock(ExerciseBlock block) =>
    block.exercises.map(formatPrescription).join(' + ');
