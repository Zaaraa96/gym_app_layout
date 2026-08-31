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
          summary: 'quads and core',
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
    expect(restored.days.single.summary, 'quads and core');
    expect(restored.days.single.blocks.single.exercises.single.title, 'squat');
  });

  test('plan DTO falls back on unknown enums and copies Map days/sections', () {
    final restored = PlanDto.fromJson({
      'id': 'plan-uuid',
      'title': 'plan 1',
      'source': 'not-a-source',
      'createdAt': '2026-08-01T00:00:00.000Z',
      'updatedAt': '2026-08-02T00:00:00.000Z',
      'days': [
        {
          'dayId': 'day-1',
          'title': 'day 1',
          'blocks': [
            Map<dynamic, dynamic>.from({
              'blockId': 'block-1',
              'kind': 'mystery',
              'svgPath': 'assets/image/upper-body.svg',
              'mediaUri': null,
              'mediaSource': 'nope',
              'mediaKind': 'gif',
              'exercises': [
                {
                  'prescriptionId': 'p-1',
                  'title': 'squat',
                  'prescribedSets': 3,
                  'prescribedReps': 10,
                  'targetWeightKg': 40,
                },
              ],
            }),
          ],
        },
      ],
      'commonSections': [
        {
          'sectionId': 'sec-abs',
          'title': 'abs',
          'blocks': const [],
        },
      ],
    }).toEntity();

    expect(restored.source, PlanSource.created);
    expect(restored.days.single.summary, '');
    expect(restored.days.single.blocks.single.kind, BlockKind.single);
    expect(
      restored.days.single.blocks.single.mediaSource,
      ExerciseMediaSource.none,
    );
    expect(restored.days.single.blocks.single.mediaKind, ExerciseMediaKind.gif);
    expect(
      restored.days.single.blocks.single.exercises.single.targetWeightKg,
      40.0,
    );
    expect(restored.commonSections.single.sectionId, 'sec-abs');
  });

  test('session DTO round-trips logs and falls back when updatedAt is missing',
      () {
    final session = WorkoutSession.create(
      uuid: 'sess-uuid',
      planId: 'plan-uuid',
      planDayId: 'day-1',
      planTitleSnapshot: 'plan 1',
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
      updatedAt: DateTime.utc(2026, 8, 15, 11),
      endedAt: DateTime.utc(2026, 8, 15, 12),
      status: SessionStatus.completed,
      includedCommonSectionIds: const ['sec-abs'],
      exerciseLogs: [
        ExerciseLog.create(
          prescriptionId: 'p-1',
          blockId: 'block-1',
          blockKind: BlockKind.superset,
          fromCommonSection: false,
          exerciseTitle: 'squat',
          exerciseTitleKey: 'squat',
          prescribedSets: 3,
          prescribedReps: 10,
          difficulty: 2,
          completedAt: DateTime.utc(2026, 8, 15, 11, 30),
          sets: [
            SetLog.create(
              setIndex: 1,
              completedAt: DateTime.utc(2026, 8, 15, 11, 5),
              reps: 10,
              weightKg: 40.5,
            ),
          ],
        ),
      ],
    )..id = 7;

    final json = SessionDto.fromEntity(session).toJson();
    expect(json.containsKey('dirty'), isFalse);
    expect(json['includedCommonSectionIds'], ['sec-abs']);
    expect(json['endedAt'], isNotNull);

    final restored = SessionDto.fromJson(json).toEntity();
    expect(restored.uuid, 'sess-uuid');
    expect(restored.endedAt!.isAtSameMomentAs(DateTime.utc(2026, 8, 15, 12)),
        isTrue);
    expect(restored.includedCommonSectionIds, ['sec-abs']);
    expect(restored.exerciseLogs, hasLength(1));
    expect(restored.exerciseLogs.single.blockKind, BlockKind.superset);
    expect(restored.exerciseLogs.single.difficulty, 2);
    expect(restored.exerciseLogs.single.sets.single.weightKg, 40.5);
    expect(restored.exerciseLogs.single.sets.single.reps, 10);

    final missingUpdatedAt = Map<String, dynamic>.from(json)..remove('updatedAt');
    missingUpdatedAt.remove('exerciseLogs');
    missingUpdatedAt.remove('includedCommonSectionIds');
    missingUpdatedAt['status'] = 'not-a-status';
    final fallback = SessionDto.fromJson(missingUpdatedAt).toEntity();
    expect(
      fallback.updatedAt.isAtSameMomentAs(DateTime.utc(2026, 8, 15, 10)),
      isTrue,
    );
    expect(fallback.status, SessionStatus.completed);
    expect(fallback.exerciseLogs, isEmpty);
    expect(fallback.includedCommonSectionIds, isEmpty);
  });

  test('plan DTO keeps duration prescriptions through a round-trip', () {
    final plan = WorkoutPlan.create(
      uuid: 'plan-uuid',
      title: 'holds',
      source: PlanSource.created,
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
                  prescriptionId: 'p-plank',
                  title: 'plank',
                  prescribedSets: 1,
                  prescribedDurationSeconds: 45,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final restored = PlanDto.fromJson(PlanDto.fromEntity(plan).toJson()).toEntity();
    final exercise = restored.days.single.blocks.single.exercises.single;
    expect(exercise.prescribedDurationSeconds, 45);
    expect(exercise.prescribedReps, isNull);
    expect(exercise.prescribedSets, 1);
  });

  test('session DTO round-trips duration set logs and Map-typed nested sets',
      () {
    final session = WorkoutSession.create(
      uuid: 'sess-uuid',
      planId: 'plan-uuid',
      planDayId: 'day-1',
      planTitleSnapshot: 'plan 1',
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 15, 10),
      updatedAt: DateTime.utc(2026, 8, 15, 11),
      endedAt: DateTime.utc(2026, 8, 15, 12),
      status: SessionStatus.completed,
      exerciseLogs: [
        ExerciseLog.create(
          prescriptionId: 'p-plank',
          blockId: 'block-abs',
          blockKind: BlockKind.single,
          fromCommonSection: true,
          exerciseTitle: 'plank',
          exerciseTitleKey: 'plank',
          prescribedSets: 1,
          prescribedDurationSeconds: 30,
          difficulty: 3,
          completedAt: DateTime.utc(2026, 8, 15, 11, 30),
          sets: [
            SetLog.create(
              setIndex: 1,
              completedAt: DateTime.utc(2026, 8, 15, 11, 5),
              durationSeconds: 35,
            ),
          ],
        ),
      ],
    );

    final json = SessionDto.fromEntity(session).toJson();
    final logJson = (json['exerciseLogs'] as List).single as Map;
    expect(logJson['prescribedDurationSeconds'], 30);
    expect(logJson['fromCommonSection'], isTrue);
    expect(logJson['sets'].single['durationSeconds'], 35);
    expect(logJson['sets'].single['reps'], isNull);

    final restored = SessionDto.fromJson(json).toEntity();
    expect(restored.exerciseLogs.single.prescribedDurationSeconds, 30);
    expect(restored.exerciseLogs.single.fromCommonSection, isTrue);
    expect(restored.exerciseLogs.single.sets.single.durationSeconds, 35);
    expect(restored.exerciseLogs.single.sets.single.reps, isNull);
    expect(restored.exerciseLogs.single.sets.single.weightKg, isNull);

    final setJson = Map<String, dynamic>.from(logJson['sets'].single as Map);
    final fromMaps = SessionDto.fromJson({
      ...json,
      'exerciseLogs': [
        Map<dynamic, dynamic>.from({
          ...Map<String, dynamic>.from(logJson),
          'sets': [Map<dynamic, dynamic>.from(setJson)],
        }),
      ],
    }).toEntity();
    expect(fromMaps.exerciseLogs.single.sets.single.durationSeconds, 35);
    expect(fromMaps.exerciseLogs.single.fromCommonSection, isTrue);
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
