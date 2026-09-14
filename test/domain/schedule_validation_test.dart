import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_validation.dart';
import 'package:gym_app/domain/reminder_prefs.dart';

void main() {
  test('weekday map must be complete before Finish when Week', () {
    final plan = WorkoutPlan.create(
      title: 'Week plan',
      source: PlanSource.created,
      status: PlanStatus.draft,
      scheduleMode: ScheduleMode.week,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      days: [
        PlanDay.create(
          dayId: 'd1',
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
        PlanDay.create(
          dayId: 'd2',
          title: 'Day 2',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b2',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p2',
                  title: 'press',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
      ],
      // Only first day mapped — sequential default would map both; clear after.
      weekdayMap: [DayWeekdayMap(dayId: 'd1', weekdays: const [1])],
    );
    // Incomplete: day 2 has no weekday.
    expect(weekdayMapIsComplete(plan), isFalse);
    expect(planCanActivate(plan), isFalse);

    setWeekdaysForDay(plan, 'd2', const [2]);
    expect(planCanActivate(plan), isTrue);
  });

  test('once mode does not require a weekday map', () {
    final plan = WorkoutPlan.create(
      title: 'Once',
      source: PlanSource.created,
      scheduleMode: ScheduleMode.once,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      days: [
        PlanDay.create(
          dayId: 'd1',
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
    expect(planCanActivate(plan), isTrue);
  });

  test('reminder fires only when enabled and a workout is due', () {
    expect(reminderShouldFire(enabled: true, workoutDueCount: 1), isTrue);
    expect(reminderShouldFire(enabled: true, workoutDueCount: 0), isFalse);
    expect(reminderShouldFire(enabled: false, workoutDueCount: 2), isFalse);
  });

  test('starter two-day map uses Mon+Thu / Tue+Fri', () {
    final days = [
      PlanDay.create(dayId: 'a', title: 'A'),
      PlanDay.create(dayId: 'b', title: 'B'),
    ];
    final map = starterTwoDayWeekdayMap(days);
    expect(map[0].weekdays, [1, 3, 4, 6]);
    expect(map[1].weekdays, [2, 5, 7]);
  });

  test('assigning a weekday moves it off any other day', () {
    final plan = WorkoutPlan.create(
      title: 'Overlap',
      source: PlanSource.created,
      scheduleMode: ScheduleMode.week,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      days: [
        PlanDay.create(dayId: 'd1', title: 'Day 1'),
        PlanDay.create(dayId: 'd3', title: 'Day 3'),
      ],
      weekdayMap: [
        DayWeekdayMap(dayId: 'd1', weekdays: const [1, 4]),
        DayWeekdayMap(dayId: 'd3', weekdays: const [3]),
      ],
    );

    setWeekdaysForDay(plan, 'd3', const [1, 3]);

    expect(weekdaysForDay(plan, 'd1'), [4]);
    expect(weekdaysForDay(plan, 'd3'), [1, 3]);
  });

  test('unassignedWorkoutDays lists training days with no weekday', () {
    final plan = WorkoutPlan.create(
      title: 'Gaps',
      source: PlanSource.created,
      scheduleMode: ScheduleMode.week,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      days: [
        PlanDay.create(
          dayId: 'd1',
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
        PlanDay.create(
          dayId: 'd2',
          title: 'Day 2',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b2',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p2',
                  title: 'press',
                  prescribedSets: 3,
                  prescribedReps: 10,
                ),
              ],
            ),
          ],
        ),
      ],
      weekdayMap: [DayWeekdayMap(dayId: 'd1', weekdays: const [1])],
    );

    final missing = unassignedWorkoutDays(plan);
    expect(missing, hasLength(1));
    expect(missing.single.title, 'Day 2');
    expect(
      requiredIssuesFor(plan).any((i) => i.message.contains('Day 2')),
      isTrue,
    );
  });
}
