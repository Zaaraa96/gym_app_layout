import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/isar/mappers.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:isar/isar.dart';

void main() {
  test('plan mapper round-trips nested days, commons, and local ids', () {
    final now = DateTime.utc(2026, 8, 24, 12);
    final plan = WorkoutPlan.create(
      uuid: 'plan-uuid',
      dirty: false,
      title: 'plan 1',
      source: PlanSource.imported,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'day 1',
          summary: 'upper',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-ss',
              kind: BlockKind.superset,
              svgPath: 'assets/image/upper-body.svg',
              mediaUri: 'assets/image/exercises/kang-squat.png',
              mediaSource: ExerciseMediaSource.asset,
              mediaKind: ExerciseMediaKind.image,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-kang',
                  title: 'kang squat',
                  prescribedSets: 3,
                  prescribedReps: 12,
                  targetWeightKg: 40,
                ),
              ],
            ),
          ],
        ),
      ],
      commonSections: [
        CommonSection.create(
          sectionId: 'sec-abs',
          title: 'abs',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-abs',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-shoot',
                  title: 'shoot out',
                  prescribedSets: 1,
                  prescribedDurationSeconds: 30,
                ),
              ],
            ),
          ],
        ),
      ],
    )..id = 7;

    final row = planToIsar(plan);
    expect(row.id, 7);
    expect(row.uuid, 'plan-uuid');
    expect(row.days.single.blocks.single.mediaKind, ExerciseMediaKind.image);

    final restored = planFromIsar(row);
    expect(restored.id, 7);
    expect(restored.uuid, 'plan-uuid');
    expect(restored.title, 'plan 1');
    expect(restored.source, PlanSource.imported);
    expect(restored.days.single.summary, 'upper');
    expect(restored.days.single.blocks.single.exercises.single.targetWeightKg, 40);
    expect(restored.commonSections.single.sectionId, 'sec-abs');
    expect(
      restored.commonSections.single.blocks.single.exercises.single
          .prescribedDurationSeconds,
      30,
    );
  });

  test('unsaved plans map to Isar.autoIncrement, not a product id', () {
    final now = DateTime.utc(2026, 8, 1);
    final plan = WorkoutPlan.create(
      title: 'new',
      source: PlanSource.created,
      createdAt: now,
      updatedAt: now,
    );
    expect(plan.id, unassignedLocalId);
    expect(planToIsar(plan).id, Isar.autoIncrement);
  });

  test('session mapper round-trips logs and keeps the local row id', () {
    final started = DateTime.utc(2026, 8, 15, 10);
    final session = WorkoutSession.create(
      uuid: 'sess-uuid',
      dirty: true,
      planId: 'plan-uuid',
      planDayId: 'day-1',
      planTitleSnapshot: 'plan 1',
      dayTitleSnapshot: 'day 1',
      startedAt: started,
      updatedAt: started,
      status: SessionStatus.inProgress,
      includedCommonSectionIds: const ['sec-abs'],
      exerciseLogs: [
        ExerciseLog.create(
          prescriptionId: 'p-kang',
          blockId: 'block-ss',
          blockKind: BlockKind.superset,
          fromCommonSection: false,
          exerciseTitle: 'kang squat',
          exerciseTitleKey: 'kang squat',
          prescribedSets: 3,
          prescribedReps: 12,
          sets: [
            SetLog.create(
              setIndex: 1,
              completedAt: started,
              reps: 12,
              weightKg: 40,
            ),
          ],
        ),
      ],
    )..id = 9;

    final restored = sessionFromIsar(sessionToIsar(session));
    expect(restored.id, 9);
    expect(restored.uuid, 'sess-uuid');
    expect(restored.planId, 'plan-uuid');
    expect(restored.includedCommonSectionIds, ['sec-abs']);
    expect(restored.exerciseLogs.single.sets.single.weightKg, 40);
    expect(restored.exerciseLogs.single.isComplete, isFalse);
  });
}
