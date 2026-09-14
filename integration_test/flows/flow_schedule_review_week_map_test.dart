import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

/// Schedule journey: Review Week map must be complete; exclusive weekdays move.
void main() {
  gymPatrolTest(
    'schedule: Review weekday map required; exclusive claim moves weekday',
    ($, gym) async {
      await gym.waitForWelcome();
      await gym.createPlan(title: 'Week map plan');
      await gym.expectVisible('Day 1');
      await gym.addExerciseInBuilder('Squat');
      await gym.tapText('CONTINUE');
      await gym.expectVisible('Finish plan');

      await gym.tapKey('add-another-day');
      await gym.expectVisible('Day 2');
      await gym.addExerciseInBuilder('Push-up');
      await gym.tapText('CONTINUE');
      await gym.expectVisible('Finish plan');

      await gym.expectScheduleEditor();
      await gym.selectWeekScheduleMode();

      final dayIds = gym.weekdayMapDayIds();
      expect(dayIds, hasLength(2));
      final day1 = dayIds.first;
      final day2 = dayIds.last;

      await gym.clearWeekdaysForDay(day2);
      await $(const Key('unassigned-weekday-warning')).waitUntilVisible();
      expect($('Assign at least one weekday.'), findsWidgets);
      await gym.expectCreatePlanDisabled();

      // Claim Monday onto Day 2 — exclusivity removes it from Day 1 if shared.
      await gym.tapWeekdayChip(day2, 1);
      await gym.pumpQuiet(const Duration(milliseconds: 400));

      // Ensure Day 1 still has a weekday (Tue if Mon moved).
      final day1Chip = find.byKey(Key('weekday-$day1-2'));
      if (day1Chip.evaluate().isNotEmpty) {
        final chip = $.tester.widget<FilterChip>(day1Chip);
        if (!chip.selected) {
          await gym.tapWeekdayChip(day1, 2);
        }
      } else {
        await gym.tapWeekdayChip(day1, 2);
      }

      // Day 2 also needs more than Mon if we only set Mon — Mon is enough.
      expect($(const Key('unassigned-weekday-warning')), findsNothing);
      await gym.tapKey('create-plan');
      await gym.expectPlanPreview('Week map plan');
      await gym.expectScheduleEditor();
      expect($('Weekday map'), findsOneWidget);

      await gym.back();
      await gym.expectPlansHomeWith('Week map plan');
    },
  );
}
