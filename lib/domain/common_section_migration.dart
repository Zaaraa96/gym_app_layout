import 'models/workout_plan.dart';

/// Converts legacy common sections into ordinary [PlanDay]s.
///
/// Title collisions append ` (extras)`. [CommonSection.sectionId] is reused as
/// [PlanDay.dayId] so nested block and prescription ids stay intact.
List<PlanDay> migrateCommonSectionsToDays({
  required List<PlanDay> days,
  required List<CommonSection> sections,
}) {
  if (sections.isEmpty) return List<PlanDay>.from(days);
  final result = List<PlanDay>.from(days);
  final titles = {for (final day in result) day.title};
  for (final section in sections) {
    var title = section.title;
    if (titles.contains(title)) {
      title = '$title (extras)';
    }
    titles.add(title);
    result.add(
      PlanDay.create(
        dayId: section.sectionId,
        title: title,
        blocks: [
          for (final block in section.blocks)
            ExerciseBlock.create(
              blockId: block.blockId,
              kind: block.kind,
              svgPath: block.svgPath,
              mediaUri: block.mediaUri,
              mediaSource: block.mediaSource,
              mediaKind: block.mediaKind,
              exercises: [
                for (final exercise in block.exercises)
                  ExercisePrescription.create(
                    prescriptionId: exercise.prescriptionId,
                    title: exercise.title,
                    prescribedSets: exercise.prescribedSets,
                    prescribedReps: exercise.prescribedReps,
                    prescribedDurationSeconds: exercise.prescribedDurationSeconds,
                    targetWeightKg: exercise.targetWeightKg,
                    targetAreaIds: List<String>.from(exercise.targetAreaIds),
                    catalogExerciseId: exercise.catalogExerciseId,
                    svgPath: exercise.svgPath,
                    mediaUri: exercise.mediaUri,
                    mediaSource: exercise.mediaSource,
                    mediaKind: exercise.mediaKind,
                  ),
              ],
            ),
        ],
      ),
    );
  }
  return result;
}
