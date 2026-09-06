import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2a two-day: Welcome installs Beginner 2-day',
    ($, gym) async {
      await gym.waitForWelcome();
      await gym.openBeginnerFromWelcome();
      await gym.useStarterTwoDay();
      await gym.expectPlansHomeWith(GymApp.twoDayTitle);
      expect($('Today: Day A — Squat and push'), findsOneWidget);
      expect($('2 days'), findsOneWidget);
      expect($("Start today's workout"), findsOneWidget);
    },
  );
}
