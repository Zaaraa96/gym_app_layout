import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2b: create from scratch via stepper, resume draft, then start',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.createPlan(title: '');
      expect($('Create plan'), findsOneWidget);
      expect($('Plan details'), findsOneWidget);

      await $(const Key('plan-name-field')).enterText('Scratch week');
      await gym.tapKey('continue-plan-details');
      await gym.expectVisible('Day 1');

      await gym.back();
      await gym.pumpQuiet(const Duration(milliseconds: 600));
      expect($('Scratch week'), findsWidgets);
      expect($('Draft'), findsOneWidget);

      await gym.tapText('Resume');
      await gym.expectVisible('Create plan');
      await gym.tapText('Day 1');
      await gym.expectVisible('Add exercise');

      await gym.tapText('Add exercise');
      await gym.enterAddExerciseTitle('Bodyweight squat');
      await gym.tapText('ADD EXERCISE');
      await gym.tapText('CONTINUE');
      await gym.expectVisible('Finish plan');
      await gym.tapKey('create-plan');
      await gym.expectVisible('Scratch week');

      await gym.openDayByTitle('Day 1');
      await gym.tapText('Start workout');
      await $('Log what you did on this set.').waitUntilVisible();
      await gym.tapLogSet();
      await gym.endAndDiscard();
      expect($('Continue workout'), findsNothing);
    },
  );
}
