import '../../domain/models/catalog_exercise.dart';
import '../../domain/models/enums.dart';

String formatCatalogPrescription(CatalogExercise exercise) {
  if (exercise.prescriptionType == PrescriptionType.timed) {
    final seconds = exercise.defaultDurationSeconds ?? 0;
    return '${exercise.defaultSets} × ${seconds}s';
  }
  return '${exercise.defaultSets} × ${exercise.defaultReps ?? 0}';
}
