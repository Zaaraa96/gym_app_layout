import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/isar/mappers.dart';
import 'package:gym_app/data/isar/workout_plan.dart' as isar_plan;
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
        PlanDay.create(
          dayId: 'sec-abs',
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
    expect(row.days.first.blocks.single.mediaKind, ExerciseMediaKind.image);

    final restored = planFromIsar(row);
    expect(restored.id, 7);
    expect(restored.uuid, 'plan-uuid');
    expect(restored.title, 'plan 1');
    expect(restored.source, PlanSource.imported);
    expect(restored.days.first.summary, 'upper');
    expect(restored.days.first.blocks.single.exercises.single.targetWeightKg, 40);
    expect(restored.days, hasLength(2));
    expect(restored.days.last.dayId, 'sec-abs');
    expect(
      restored.days.last.blocks.single.exercises.single
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

  test('round-trips status, description, goals, and target areas', () {
    final now = DateTime.utc(2026, 9, 7);
    final plan = WorkoutPlan.create(
      uuid: 'draft-uuid',
      title: 'Push',
      description: 'Upper body',
      goalIds: const ['build-strength', 'build-muscle'],
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p1',
                  title: 'bench press',
                  prescribedSets: 4,
                  prescribedReps: 6,
                  targetAreaIds: const ['chest', 'triceps', 'front-shoulders'],
                ),
              ],
            ),
          ],
        ),
      ],
    )..id = 3;

    final restored = planFromIsar(planToIsar(plan));
    expect(restored.status, PlanStatus.draft);
    expect(restored.description, 'Upper body');
    expect(restored.goalIds, ['build-strength', 'build-muscle']);
    expect(
      restored.days.single.blocks.single.exercises.single.targetAreaIds,
      ['chest', 'triceps', 'front-shoulders'],
    );
  });

  test('planFromIsar converts leftover common sections into days', () {
    final now = DateTime.utc(2026, 9, 7);
    final row = isar_plan.WorkoutPlan()
      ..id = 4
      ..uuid = 'legacy'
      ..dirty = false
      ..title = 'Legacy'
      ..description = ''
      ..goalIds = []
      ..source = PlanSource.created
      ..status = PlanStatus.active
      ..createdAt = now
      ..updatedAt = now
      ..days = [
        isar_plan.PlanDay()
          ..dayId = 'day-1'
          ..title = 'abs'
          ..summary = ''
          ..blocks = [],
      ]
      ..commonSections = [
        isar_plan.CommonSection()
          ..sectionId = 'sec-abs'
          ..title = 'abs'
          ..blocks = [
            isar_plan.ExerciseBlock()
              ..blockId = 'b-abs'
              ..kind = BlockKind.single
              ..exercises = [
                isar_plan.ExercisePrescription()
                  ..prescriptionId = 'p-abs'
                  ..title = 'plank'
                  ..prescribedSets = 1
                  ..prescribedDurationSeconds = 30,
              ],
          ],
      ];

    final restored = planFromIsar(row);
    expect(restored.days.map((day) => day.title), ['abs', 'abs (extras)']);
    expect(restored.days.last.blocks.single.exercises.single.title, 'plank');
  });

  test('missing PlanStatus is active so pre-field rows stay startable', () {
    expect(PlanStatus.values.first, PlanStatus.active);
    expect(PlanStatus.active.index, 0);
    expect(PlanStatus.draft.index, 1);

    final now = DateTime.utc(2026, 9, 7);
    final created = WorkoutPlan.create(
      title: 'Imported before drafts',
      source: PlanSource.imported,
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
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(created.status, PlanStatus.active);
    expect(planToIsar(created).status.index, 0);
    expect(planFromIsar(planToIsar(created)).status, PlanStatus.active);

    final row = isar_plan.WorkoutPlan()
      ..id = 5
      ..uuid = 'legacy-no-status'
      ..dirty = false
      ..title = 'Legacy'
      ..source = PlanSource.imported
      ..createdAt = now
      ..updatedAt = now;
    expect(row.status, PlanStatus.active);
    expect(planFromIsar(row).status, PlanStatus.active);
  });
}
