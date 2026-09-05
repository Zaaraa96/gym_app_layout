import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2b + 5d: create a blank plan, empty start snackbar, then discard',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.createPlan(title: '');
      expect($('Add a title before saving'), findsOneWidget);

      await $(TextFormField).at(0).enterText('Scratch week');
      await gym.tapText('save');
      await gym.expectVisible('Day 1');
      expect($('Scratch week'), findsWidgets);

      await gym.openDayByTitle('Day 1');
      expect($('No exercises on this day yet.'), findsOneWidget);

      await gym.back();
      await gym.addEmptyCommonSection('abs');
      await gym.openDayByTitle('Day 1');
      await gym.tapText('Start workout');
      await gym.expectVisible('Include today');
      await gym.tapKey('confirm-include');
      expect(
        $('Turn on a section or add an exercise first.'),
        findsOneWidget,
      );

      await gym.tapText('Edit day');
      await gym.tapText('Add exercise');
      await gym.enterAddExerciseTitle('Bodyweight squat');
      await gym.tapText('Save exercise');
      await gym.tapText('Save');
      await gym.tapText('Start workout');
      await gym.confirmCommonsOff();
      await gym.tapLogSet();
      await gym.endAndDiscard();
      expect($('Continue workout'), findsNothing);
    },
  );
}
