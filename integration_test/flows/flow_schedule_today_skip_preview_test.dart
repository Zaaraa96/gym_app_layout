import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

/// Schedule journey: starter Week plan → Today list + Schedule/Progress + reminder + Skip.
void main() {
  gymPatrolTest(
    'schedule: Today list, Schedule/Progress, reminder, On schedule off, Skip day',
    ($, gym) async {
      await gym.installTwoDayFromWelcome();
      await gym.expectTodayList();
      expect($("Start today's workout"), findsOneWidget);

      await gym.openReminderSettings();
      expect($('Workout reminder'), findsWidgets);
      await gym.closeReminderSettings();
      await gym.expectPlansHomeWith(GymApp.twoDayTitle);

      await gym.openPlan(GymApp.twoDayTitle);
      await gym.expectScheduleEditor();
      expect($('Week schedule'), findsWidgets);
      expect($('Weekday map'), findsOneWidget);
      await gym.expectPlanProgress();

      await gym.toggleOnSchedule();
      await gym.back();
      await gym.expectNothingOnScheduleBanner();
      expect($(GymApp.twoDayTitle), findsWidgets);

      await gym.openPlan(GymApp.twoDayTitle);
      await gym.toggleOnSchedule();
      await gym.back();
      await gym.expectTodayList();

      await gym.skipTodaysWorkout();
      await gym.pumpQuiet(const Duration(milliseconds: 600));
      expect($('Skip day'), findsNothing);
      expect($(GymApp.twoDayTitle), findsWidgets);
    },
  );
}
