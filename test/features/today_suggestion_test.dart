import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/memory_skip_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/today_suggestion.dart';

void main() {
  group('once mode', () {
    test('with no history, the first startable day is due', () {
      final plan = _oncePlan(id: 1, titles: ['Day 1', 'Day 2']);
      final items = suggestTodayItems(plans: [plan]);
      expect(items, hasLength(1));
      expect(items.single.day!.title, 'Day 1');
      expect(items.single.isWorkout, isTrue);
      expect(items.single.alreadyTrainedToday, isFalse);
    });

    test('after completing a day, the next startable day is due', () {
      final plan = _oncePlan(id: 1, titles: ['Day 1', 'Day 2', 'Day 3']);
      final items = suggestTodayItems(
        plans: [plan],
        completedNewestFirst: [
          _completed(planId: '1', dayId: 'day-1', at: DateTime.utc(2026, 8, 26)),
        ],
        now: DateTime.utc(2026, 8, 27, 12),
      );
      expect(items.single.day!.title, 'Day 2');
    });

    test('completing the last day finishes the plan — no wrap, no Rest', () {
      final plan = _oncePlan(id: 1, titles: ['Day 1', 'Day 2']);
      final items = suggestTodayItems(
        plans: [plan],
        completedNewestFirst: [
          _completed(planId: '1', dayId: 'day-1', at: DateTime.utc(2026, 8, 25)),
          _completed(planId: '1', dayId: 'day-2', at: DateTime.utc(2026, 8, 26)),
        ],
        now: DateTime.utc(2026, 8, 27),
      );
      expect(items, isEmpty);
    });

    test('skip advances to the next day without a session', () {
      final plan = _oncePlan(id: 1, titles: ['Day 1', 'Day 2']);
      final items = suggestTodayItems(
        plans: [plan],
        skips: [
          PlanDaySkip.create(
            planId: '1',
            dayId: 'day-1',
            date: DateTime.utc(2026, 8, 28),
          ),
        ],
        now: DateTime.utc(2026, 8, 28, 18),
      );
      expect(items.single.day!.title, 'Day 2');
      expect(items.single.alreadyTrainedToday, isTrue);
    });

    test('never emits Rest for once mode', () {
      final plan = _oncePlan(id: 1, titles: ['Day 1']);
      // Monday local — once mode ignores calendar.
      final items = suggestTodayItems(
        plans: [plan],
        now: DateTime(2026, 8, 31), // Monday
      );
      expect(items.every((i) => i.isWorkout), isTrue);
    });
  });

  group('week mode', () {
    test('maps today\'s weekday to the due workout', () {
      final plan = _weekPlan(
        id: 1,
        titles: ['Day A', 'Day B'],
        map: {
          'day-1': [1, 4], // Mon Thu
          'day-2': [2, 5], // Tue Fri
        },
      );
      // Wednesday 2026-09-02 local — Rest
      final wed = suggestTodayItems(
        plans: [plan],
        now: DateTime(2026, 9, 2, 12),
      );
      expect(wed, hasLength(1));
      expect(wed.single.isRest, isTrue);

      // Monday — Day A
      final mon = suggestTodayItems(
        plans: [plan],
        now: DateTime(2026, 8, 31, 12),
      );
      expect(mon.single.isWorkout, isTrue);
      expect(mon.single.day!.title, 'Day A');
    });

    test('skip clears today\'s due workout', () {
      final plan = _weekPlan(
        id: 1,
        titles: ['Day A'],
        map: {
          'day-1': [1],
        },
      );
      final now = DateTime(2026, 8, 31, 12); // Monday
      final items = suggestTodayItems(
        plans: [plan],
        skips: [
          PlanDaySkip.create(
            planId: '1',
            dayId: 'day-1',
            date: now,
          ),
        ],
        now: now,
      );
      expect(items, isEmpty);
    });
  });

  test('off-schedule active plans do not feed Today', () {
    final plan = _oncePlan(id: 1, titles: ['Day 1'])..onSchedule = false;
    expect(suggestTodayItems(plans: [plan]), isEmpty);
  });

  test('multi-plan Today lists every due workout', () {
    final a = _oncePlan(id: 1, titles: ['A1']);
    final b = _oncePlan(id: 2, titles: ['B1']);
    final items = suggestTodayItems(plans: [a, b]);
    expect(items.where((i) => i.isWorkout), hasLength(2));
  });

  test('drafts are ignored', () {
    final plan = _oncePlan(id: 1, titles: ['Day 1'])
      ..status = PlanStatus.draft;
    expect(suggestTodayItems(plans: [plan]), isEmpty);
  });

  test('returns null from suggestToday when only Rest is due', () {
    final plan = _weekPlan(
      id: 1,
      titles: ['Day A'],
      map: {
        'day-1': [1],
      },
    );
    final suggestion = suggestToday(
      plans: [plan],
      now: DateTime(2026, 9, 2, 12), // Wed
    );
    expect(suggestion, isNull);
    expect(
      suggestTodayItems(plans: [plan], now: DateTime(2026, 9, 2, 12)),
      hasLength(1),
    );
  });

  test('sameUtcDay is true across clock times on that UTC date', () {
    expect(
      sameUtcDay(
        DateTime.utc(2026, 8, 28, 1),
        DateTime.utc(2026, 8, 28, 23),
      ),
      isTrue,
    );
    expect(
      sameUtcDay(
        DateTime.utc(2026, 8, 28, 23),
        DateTime.utc(2026, 8, 29),
      ),
      isFalse,
    );
  });

  test('loadHomeOverview reads repositories and suggests the next day', () async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final skips = MemorySkipRepository();
    final plan = _oncePlan(id: 1, titles: ['Day 1', 'Day 2']);
    await plans.save(plan);
    await sessions.save(
      _completed(
        planId: plan.uuid,
        dayId: 'day-1',
        at: DateTime.utc(2026, 8, 26),
      ),
    );

    final overview = await loadHomeOverview(
      plans: plans,
      sessions: sessions,
      skips: skips,
      now: DateTime.utc(2026, 8, 27, 12),
    );
    expect(overview.plans.single.uuid, plan.uuid);
    expect(overview.live, isNull);
    expect(overview.todayItems, hasLength(1));
    expect(overview.today!.day!.title, 'Day 2');
  });

  test('loadHomeOverview ignores drafts when suggesting today', () async {
    final plans = MemoryPlanRepository();
    final sessions = MemorySessionRepository();
    final now = DateTime.utc(2026, 8, 28);
    final draft = WorkoutPlan.create(
      title: 'Draft only',
      source: PlanSource.created,
      status: PlanStatus.draft,
      scheduleMode: ScheduleMode.once,
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
    await plans.save(draft);

    final overview = await loadHomeOverview(
      plans: plans,
      sessions: sessions,
      now: now,
    );
    expect(overview.plans, hasLength(1));
    expect(overview.todayItems, isEmpty);
  });
}

WorkoutPlan _oncePlan({
  required int id,
  required List<String> titles,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'plan $id',
    source: PlanSource.created,
    scheduleMode: ScheduleMode.once,
    onSchedule: true,
    createdAt: now,
    updatedAt: now,
    days: [
      for (var i = 0; i < titles.length; i++)
        PlanDay.create(
          dayId: 'day-${i + 1}',
          title: titles[i],
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-$id-$i',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-$id-$i',
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
    ],
  )
    ..id = id
    ..uuid = '$id';
}

WorkoutPlan _weekPlan({
  required int id,
  required List<String> titles,
  required Map<String, List<int>> map,
}) {
  final plan = _oncePlan(id: id, titles: titles);
  plan.scheduleMode = ScheduleMode.week;
  plan.weekdayMap = [
    for (final entry in map.entries)
      DayWeekdayMap(dayId: entry.key, weekdays: entry.value),
  ];
  return plan;
}

WorkoutSession _completed({
  required String planId,
  required String dayId,
  required DateTime at,
}) {
  return WorkoutSession.create(
    planId: planId,
    planDayId: dayId,
    planTitleSnapshot: 'plan',
    dayTitleSnapshot: dayId,
    startedAt: at,
    status: SessionStatus.completed,
  );
}
