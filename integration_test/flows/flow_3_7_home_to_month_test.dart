import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '3–7: home, day, live (6c/6d), snapshot edit, then Month',
    ($, gym) async {
      await gym.installFullBodyFromWelcome();
      expect($(const Key('continue-banner')), findsNothing);
      expect($('Import'), findsOneWidget);
      expect($('New'), findsOneWidget);
      expect($(const Key('open-starters')), findsOneWidget);

      await gym.openPlan(GymApp.fullBodyTitle);
      expect($(GymApp.day1Title), findsOneWidget);
      expect($('abs'), findsOneWidget);
      expect($('mobility'), findsOneWidget);

      await gym.openDayByTitle(GymApp.day1Title);
      expect($('Edit day'), findsOneWidget);
      expect($('Bodyweight squat'), findsWidgets);
      expect($('Glute bridge'), findsWidgets);
      expect($('Plank'), findsWidgets);
      await gym.back();
      await gym.back();

      await gym.startTodayLeavingCommonsOff();
      expect($('Bodyweight squat  ·  set 1 of 3'), findsOneWidget);

      await gym.tapLogSet();
      expect($('Bodyweight squat  ·  set 2 of 3'), findsOneWidget);
      await gym.tapStartRest();
      expect($('Resting…'), findsOneWidget);
      await gym.tapResetRest();
      expect($('Start rest'), findsOneWidget);

      await gym.back();
      expect($(const Key('continue-banner')), findsOneWidget);

      await gym.openPlan(GymApp.fullBodyTitle);
      await gym.openDayByTitle(GymApp.day1Title);
      await gym.tapText('Edit day');
      await gym.tapKey('add-exercise');
      await $(TextFormField).first.enterText('Ghost raise');
      await gym.tapText('Save exercise');
      await gym.tapText('Save');
      await gym.back();
      await gym.back();

      await gym.tapText('Continue workout');
      await gym.expectVisible('Log what you did on this set.');
      expect($('Ghost raise'), findsNothing);
      expect($('Bodyweight squat'), findsWidgets);

      await gym.backgroundAndReopen();
      if ($('Continue workout').exists) {
        await gym.tapText('Continue workout');
      }
      expect($('Bodyweight squat'), findsWidgets);

      await gym.back();
      await gym.openPlan(GymApp.fullBodyTitle);
      await gym.openDayByTitle(GymApp.day2Title);
      await gym.tapText('Start workout');
      await gym.expectVisible('A workout is already in progress');
      await gym.tapKey('resume-existing');
      expect($('Bodyweight squat'), findsWidgets);

      await gym.finishLiveWorkout();
      expect($('Workout complete'), findsOneWidget);
      expect($('Nice work. What you logged is saved.'), findsOneWidget);
      await gym.tapDone();

      await gym.expectPlansHomeWith(GymApp.fullBodyTitle);
      expect($(const Key('continue-banner')), findsNothing);
      expect($('Start next day'), findsOneWidget);

      await gym.openMonthTab();
      await gym.expectMonthDotForToday();
      expect($(const Key('exercise-trend-bodyweight squat')), findsOneWidget);
      await gym.openTodayOnMonth();
      expect($('Bodyweight squat'), findsWidgets);
    },
  );
}
