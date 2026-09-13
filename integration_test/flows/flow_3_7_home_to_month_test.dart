import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '3-7: home, extra days, live (superset + timed), snapshot edit, then Month',
    ($, gym) async {
      await gym.installFullBodyFromWelcome();
      expect($(const Key('continue-banner')), findsNothing);
      expect($('Import'), findsOneWidget);
      expect($('New'), findsOneWidget);
      expect($(const Key('open-starters')), findsOneWidget);
      expect($('Exercises'), findsOneWidget);
      expect($('Month'), findsOneWidget);
      expect($('5 days'), findsOneWidget);

      await gym.openPlan(GymApp.fullBodyTitle);
      expect($(GymApp.day1Title), findsOneWidget);
      expect($('abs'), findsOneWidget);
      expect($('mobility'), findsOneWidget);

      await gym.openDayByTitle('abs');
      expect($('Edit day'), findsOneWidget);
      expect($('Start workout'), findsOneWidget);
      await gym.back();

      await gym.openDayByTitle(GymApp.day1Title);
      expect($('Edit day'), findsOneWidget);
      expect($('Bodyweight squat'), findsWidgets);
      expect($('Glute bridge'), findsWidgets);
      expect($('Plank'), findsWidgets);
      await gym.back();
      await gym.back();

      await gym.startTodaysWorkoutFromHome();
      expect($('Your turn: Bodyweight squat'), findsOneWidget);
      expect($('set 1 of 3'), findsOneWidget);

      await gym.tapSaveSet();
      expect($('Breathe.'), findsOneWidget);
      expect($('Skip'), findsOneWidget);
      expect($('+15s'), findsOneWidget);
      await gym.tapAddRest15();
      await gym.tapSkipRest();
      expect($('Your turn: Bodyweight squat'), findsOneWidget);
      expect($('set 2 of 3'), findsOneWidget);
      expect($('Done with this set? Save it.'), findsOneWidget);

      await gym.back();
      expect($(const Key('continue-banner')), findsOneWidget);

      await gym.openPlan(GymApp.fullBodyTitle);
      await gym.openDayByTitle(GymApp.day1Title);
      await gym.tapText('Edit day');
      await gym.tapKey('add-exercise');
      await gym.enterAddExerciseTitle('Ghost raise');
      await gym.commitExerciseEditor();
      await gym.tapKey('save-day');
      await gym.back();
      await gym.back();

      await gym.tapText('Continue workout');
      await gym.awaitLiveLogger();
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

      await gym.finishLiveWorkout(
        expectSupersetAlternate: true,
        expectTimedWork: true,
      );
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
