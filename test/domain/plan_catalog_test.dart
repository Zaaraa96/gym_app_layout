import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_catalog.dart';

void main() {
  test('catalog match fills target areas for a recognized title', () {
    expect(
      catalogTargetAreaIdsForTitle('Bench press'),
      ['chest', 'triceps', 'front-shoulders'],
    );
  });

  test('alias match uses keywords such as rdl', () {
    expect(
      catalogTargetAreaIdsForTitle('rdl'),
      ['glutes', 'hamstrings'],
    );
  });

  test('unknown exercises keep empty target areas', () {
    expect(catalogTargetAreaIdsForTitle('mystery snatch'), isEmpty);
  });

  test('manual target-area edits are not catalog defaults', () {
    expect(
      targetAreasMatchCatalog('bench press', ['chest']),
      isFalse,
    );
    expect(
      targetAreasMatchCatalog(
        'bench press',
        ['chest', 'triceps', 'front-shoulders'],
      ),
      isTrue,
    );
  });

  test('goals rank tagged exercises first, otherwise alphabetical', () {
    final ranked = suggestedExercisesForGoals(['mobility']);
    expect(ranked.first.id, 'step-lunge-stretch');
    final alpha = suggestedExercisesForGoals(const []);
    expect(
      alpha.first.label.toLowerCase().compareTo(alpha[1].label.toLowerCase()),
      lessThanOrEqualTo(0),
    );
  });

  test('goal guidance is advisory when a selected goal has no tagged work', () {
    final now = DateTime.utc(2026, 9, 7);
    final plan = WorkoutPlan.create(
      title: 'Strength',
      goalIds: const ['mobility'],
      source: PlanSource.created,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p',
                  title: 'bench press',
                  prescribedSets: 3,
                  prescribedReps: 8,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final notes = goalGuidanceFor(plan);
    expect(notes, isNotEmpty);
    expect(notes.single.required, isFalse);
    expect(notes.single.message, contains('Mobility'));
  });

  test('canonicalize keeps catalog order and drops unknowns', () {
    expect(
      canonicalizeTargetAreaIds(['triceps', 'nope', 'chest', 'triceps']),
      ['chest', 'triceps'],
    );
    expect(
      canonicalizeGoalIds(['mobility', 'mystery', 'build-strength']),
      ['build-strength', 'mobility'],
    );
    expect(
      canonicalizeRegionIds(['cardio', 'nope', 'abs', 'abs']),
      ['abs', 'cardio'],
    );
    expect(
      defaultRegionIdsFor(['chest', 'abs', 'quads']),
      ['abs', 'upper', 'lower'],
    );
  });
}
