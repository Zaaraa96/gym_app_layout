import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/plans/today_suggestion.dart';

void main() {
  test('with no history, the newest startable plan’s first day is today', () {
    final plan = _plan(id: 1, titles: ['Day 1', 'Day 2']);
    final suggestion = suggestToday(plans: [plan]);
    expect(suggestion, isNotNull);
    expect(suggestion!.day.title, 'Day 1');
    expect(suggestion.headline, 'Today: Day 1');
    expect(suggestion.alreadyTrainedToday, isFalse);
    expect(
      suggestion.prompt,
      'Start with squat, then log what you did.',
    );
  });

  test('after completing a day, the next startable day is suggested', () {
    final plan = _plan(id: 1, titles: ['Day 1', 'Day 2', 'Day 3']);
    final suggestion = suggestToday(
      plans: [plan],
      completedNewestFirst: [
        _completed(planId: '1', dayId: 'day-1', at: DateTime.utc(2026, 8, 26)),
      ],
      now: DateTime.utc(2026, 8, 27, 12),
    );
    expect(suggestion!.day.title, 'Day 2');
    expect(suggestion.headline, 'Today: Day 2');
    expect(suggestion.alreadyTrainedToday, isFalse);
  });

  test('completing the last day wraps to the first', () {
    final plan = _plan(id: 1, titles: ['Day 1', 'Day 2']);
    final suggestion = suggestToday(
      plans: [plan],
      completedNewestFirst: [
        _completed(planId: '1', dayId: 'day-2', at: DateTime.utc(2026, 8, 26)),
      ],
      now: DateTime.utc(2026, 8, 27),
    );
    expect(suggestion!.day.title, 'Day 1');
    expect(suggestion.alreadyTrainedToday, isFalse);
  });

  test('completing the last day today wraps and flags already trained', () {
    final plan = _plan(id: 1, titles: ['Day 1', 'Day 2']);
    final suggestion = suggestToday(
      plans: [plan],
      completedNewestFirst: [
        _completed(
          planId: '1',
          dayId: 'day-2',
          at: DateTime.utc(2026, 8, 28, 8),
        ),
      ],
      now: DateTime.utc(2026, 8, 28, 18),
    );
    expect(suggestion!.day.title, 'Day 1');
    expect(suggestion.alreadyTrainedToday, isTrue);
    expect(suggestion.headline, 'Next up: Day 1');
    expect(suggestion.prompt, contains('You already trained today'));
  });

  test('a session completed today offers the next day as later work', () {
    final plan = _plan(id: 1, titles: ['Day 1', 'Day 2']);
    final suggestion = suggestToday(
      plans: [plan],
      completedNewestFirst: [
        _completed(
            planId: '1', dayId: 'day-1', at: DateTime.utc(2026, 8, 28, 8)),
      ],
      now: DateTime.utc(2026, 8, 28, 18),
    );
    expect(suggestion!.day.title, 'Day 2');
    expect(suggestion.alreadyTrainedToday, isTrue);
    expect(suggestion.headline, 'Next up: Day 2');
    expect(suggestion.prompt, contains('You already trained today'));
  });

  test('a newer plan wins over an older one', () {
    final older =
        _plan(id: 1, titles: ['Old day'], updatedAt: DateTime.utc(2026, 1, 1));
    final newer =
        _plan(id: 2, titles: ['New day'], updatedAt: DateTime.utc(2026, 8, 1));
    final suggestion = suggestToday(plans: [newer, older]);
    expect(suggestion!.plan.id, 2);
    expect(suggestion.day.title, 'New day');
  });

  test('returns null when no day can start', () {
    final plan = WorkoutPlan.create(
      title: 'empty',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
      days: [PlanDay.create(dayId: 'day-1', title: 'Empty')],
    )
      ..id = 1
      ..uuid = '1';
    expect(suggestToday(plans: [plan]), isNull);
  });

  test('an empty day with common sections is still startable', () {
    final plan = WorkoutPlan.create(
      title: 'commons',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
      days: [PlanDay.create(dayId: 'day-1', title: 'Rest-ish')],
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
                  prescriptionId: 'p-plank',
                  title: 'plank',
                  prescribedSets: 1,
                  prescribedDurationSeconds: 30,
                ),
              ],
            ),
          ],
        ),
      ],
    )
      ..id = 1
      ..uuid = '1';

    final suggestion = suggestToday(plans: [plan]);
    expect(suggestion, isNotNull);
    expect(suggestion!.day.title, 'Rest-ish');
    expect(suggestion.prompt, 'Start with plank, then log what you did.');
  });

  test('rotation skips days that cannot start', () {
    final work = _plan(id: 1, titles: ['Day 1', 'Day 3']);
    final plan = WorkoutPlan.create(
      title: 'with rest day',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
      days: [
        work.days.first,
        PlanDay.create(dayId: 'day-empty', title: 'Empty rest'),
        PlanDay.create(
          dayId: 'day-3',
          title: 'Day 3',
          blocks: work.days.last.blocks,
        ),
      ],
    )
      ..id = 1
      ..uuid = '1';

    final suggestion = suggestToday(
      plans: [plan],
      completedNewestFirst: [
        _completed(planId: '1', dayId: 'day-1', at: DateTime.utc(2026, 8, 26)),
      ],
      now: DateTime.utc(2026, 8, 27),
    );
    expect(suggestion!.day.title, 'Day 3');
  });

  test('a completed day that is no longer startable falls back to the first',
      () {
    final plan = _plan(id: 1, titles: ['Day 1', 'Day 2']);
    final suggestion = suggestToday(
      plans: [plan],
      completedNewestFirst: [
        _completed(
          planId: '1',
          dayId: 'retired-day',
          at: DateTime.utc(2026, 8, 26),
        ),
      ],
      now: DateTime.utc(2026, 8, 27),
    );
    expect(suggestion!.day.title, 'Day 1');
    expect(suggestion.alreadyTrainedToday, isFalse);
  });

  test('firstExerciseTitle falls back when the day and commons are empty', () {
    final plan = WorkoutPlan.create(
      title: 'empty',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
      days: [PlanDay.create(dayId: 'day-1', title: 'Empty')],
      commonSections: [
        CommonSection.create(sectionId: 'sec-abs', title: 'abs'),
      ],
    );
    expect(firstExerciseTitle(plan.days.single, plan), 'your first exercise');
    expect(dayCanStart(plan, plan.days.single), isTrue);
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
}

WorkoutPlan _plan({
  required int id,
  required List<String> titles,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime.utc(2026, 8, 1);
  return WorkoutPlan.create(
    title: 'plan $id',
    source: PlanSource.created,
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
