import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

/// Schedule journey: switch starter to Run once → Skip both days → park → Run again.
void main() {
  gymPatrolTest(
    'schedule: Run once finishes off schedule, Run again restores Today',
    ($, gym) async {
      await gym.installTwoDayFromWelcome();
      await gym.expectTodayList();

      await gym.openPlan(GymApp.twoDayTitle);
      await gym.selectRunOnceMode();
      await gym.expectPlanProgress();
      await gym.back();

      await gym.expectTodayList();
      expect($('Skip day'), findsOneWidget);
      await gym.skipTodaysWorkout();
      await gym.expectTodayList();
      await gym.skipTodaysWorkout();

      await gym.expectNothingOnScheduleBanner();
      expect($(GymApp.twoDayTitle), findsWidgets);

      await gym.openPlan(GymApp.twoDayTitle);
      await gym.expectPlanProgress();
      expect(
        find.textContaining('finished and off the schedule'),
        findsOneWidget,
      );
      await gym.runOnceAgainFromPreview();
      expect(
        find.textContaining('available on Today again'),
        findsOneWidget,
      );
      await gym.back();

      await gym.expectTodayList();
      expect($("Start today's workout"), findsOneWidget);
      expect($('Skip day'), findsOneWidget);
    },
  );
}
