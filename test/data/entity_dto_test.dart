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

  test('session DTO round-trips logs, sets, and omits dirty', () {
    final session = WorkoutSession.create(
      uuid: 'sess-uuid',
      dirty: true,
      planId: 'plan-uuid',
      planDayId: 'day-1',
      planTitleSnapshot: 'plan 1',
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
      updatedAt: DateTime.utc(2026, 8, 15, 11),
      status: SessionStatus.inProgress,
      includedCommonSectionIds: const ['sec-abs'],
      exerciseLogs: [
        ExerciseLog.create(
          prescriptionId: 'p-1',
          blockId: 'block-1',
          blockKind: BlockKind.superset,
          fromCommonSection: true,
          exerciseTitle: 'plank',
          exerciseTitleKey: 'plank',
          prescribedSets: 1,
          prescribedDurationSeconds: 30,
          sets: [
            SetLog.create(
              setIndex: 1,
              completedAt: DateTime.utc(2026, 8, 15, 10, 5),
              durationSeconds: 32,
              weightKg: 0,
            ),
          ],
        ),
      ],
    )..id = 7;

    final json = SessionDto.fromEntity(session).toJson();
    expect(json.containsKey('dirty'), isFalse);
    expect(json.values, isNot(contains(7)));
    expect(json['endedAt'], isNull);
    expect(json['includedCommonSectionIds'], ['sec-abs']);

    final restored = SessionDto.fromJson(json).toEntity();
    expect(restored.uuid, 'sess-uuid');
    expect(restored.dirty, isFalse);
    expect(restored.status, SessionStatus.inProgress);
    expect(restored.endedAt, isNull);
    expect(restored.includedCommonSectionIds, ['sec-abs']);
    final log = restored.exerciseLogs.single;
    expect(log.exerciseTitle, 'plank');
    expect(log.fromCommonSection, isTrue);
    expect(log.blockKind, BlockKind.superset);
    expect(log.sets.single.durationSeconds, 32);
    expect(log.sets.single.weightKg, 0);
  });

  test('unknown enums fall back and missing lists stay empty', () {
    final session = WorkoutSession.create(
      uuid: 'sess-uuid',
      planId: 'plan-uuid',
      planDayId: 'day-1',
      planTitleSnapshot: 'plan 1',
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
      status: SessionStatus.abandoned,
    );
    final json = SessionDto.fromJson(<String, dynamic>{
      ...SessionDto.fromEntity(session).toJson(),
      'status': 'not-a-status',
      'includedCommonSectionIds': null,
      'exerciseLogs': 'not-a-list',
    });
    final restored = json.toEntity();
    expect(restored.status, SessionStatus.completed);
    expect(restored.includedCommonSectionIds, isEmpty);
    expect(restored.exerciseLogs, isEmpty);

    final planJson = PlanDto.fromEntity(
      WorkoutPlan.create(
        uuid: 'plan-uuid',
        title: 'plan 1',
        source: PlanSource.imported,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 2),
      ),
    ).toJson();
    planJson['source'] = 'mystery';
    planJson['days'] = null;
    planJson['commonSections'] = [
      {'sectionId': 'sec-1', 'title': 'abs', 'blocks': 'nope'},
    ];
    final plan = PlanDto.fromJson(planJson).toEntity();
    expect(plan.source, PlanSource.created);
    expect(plan.days, isEmpty);
    expect(plan.commonSections.single.title, 'abs');
    expect(plan.commonSections.single.blocks, isEmpty);
  });
}
