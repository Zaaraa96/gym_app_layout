import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '8: Welcome → full body → log Day 1 → next day on home → Month',
    ($, gym) async {
      await gym.installFullBodyFromWelcome();
      await gym.startTodayLeavingCommonsOff();
      await gym.finishLiveWorkout();
      await gym.tapDone();

      await gym.expectPlansHomeWith(GymApp.fullBodyTitle);
      expect($(const Key('continue-banner')), findsNothing);
      expect($('Start next day'), findsOneWidget);

      await gym.openPlan(GymApp.fullBodyTitle);
      await gym.openDayByTitle(GymApp.day2Title);
      expect($('Hip hinge'), findsWidgets);
      expect($('Edit day'), findsOneWidget);
      await gym.back();
      await gym.back();

      await gym.openMonthTab();
      await gym.expectMonthDotForToday();
      expect($(const Key('exercise-trend-bodyweight squat')), findsOneWidget);
    },
  );
}
