import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/remote/entity_dto.dart';

void main() {
  test('plan DTO round-trips uuid identity and omits the Isar row id', () {
    final plan = WorkoutPlan.create(
      uuid: 'plan-uuid',
      title: 'plan 1',
      source: PlanSource.imported,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 2),
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-1',
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
      ],
    )..id = 99;

    final json = PlanDto.fromEntity(plan).toJson();
    expect(json.containsKey('id'), isTrue);
    expect(json['id'], 'plan-uuid');
    expect(json.containsKey('dirty'), isFalse);
    expect(json.values, isNot(contains(99)));

    final restored = PlanDto.fromJson(json).toEntity();
    expect(restored.uuid, 'plan-uuid');
    expect(restored.title, 'plan 1');
    expect(restored.days.single.blocks.single.exercises.single.title, 'squat');
  });

  test('session DTO points planId at the plan uuid', () {
    final session = WorkoutSession.create(
      uuid: 'sess-uuid',
      planId: 'plan-uuid',
      planDayId: 'day-1',
      planTitleSnapshot: 'plan 1',
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
      updatedAt: DateTime.utc(2026, 8, 15, 11),
      status: SessionStatus.completed,
    )..id = 7;

    final json = SessionDto.fromEntity(session).toJson();
    expect(json['id'], 'sess-uuid');
    expect(json['planId'], 'plan-uuid');
    expect(json.values, isNot(contains(7)));
  });
}
