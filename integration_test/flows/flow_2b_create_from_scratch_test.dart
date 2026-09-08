import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2b: stepper create, untitled draft, disabled create, then start and discard',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.createPlan(title: '');
      expect($('Create plan'), findsOneWidget);
      expect($('Plan details'), findsOneWidget);
      expect($(const Key('plan-name-field')), findsOneWidget);

      await gym.back();
      await gym.pumpQuiet(const Duration(milliseconds: 600));
      expect($('Untitled plan'), findsWidgets);
      expect($('Draft'), findsOneWidget);

      await gym.tapText('Resume');
      await gym.expectVisible('Create plan');
      await $(const Key('plan-name-field')).enterText('Scratch week');
      await gym.tapKey('continue-plan-details');
      await gym.expectVisible('Day 1');
      expect($('Add at least one exercise.'), findsOneWidget);

      await gym.back();
      await gym.pumpQuiet(const Duration(milliseconds: 600));
      expect($('Scratch week'), findsWidgets);
      expect($('Draft'), findsOneWidget);

      await gym.tapText('Resume');
      await gym.expectVisible('Create plan');
      await gym.tapText('Day 1');
      await gym.expectVisible('Add exercise');

      await gym.openReviewStep();
      expect($('Fix this'), findsOneWidget);
      await gym.expectCreatePlanDisabled();
      await gym.tapText('Fix this');
      await gym.expectVisible('Add exercise');

      await gym.addExerciseInBuilder('Bodyweight squat');
      await gym.tapText('CONTINUE');
      await gym.expectVisible('CREATE PLAN');
      await gym.tapKey('create-plan');
      await gym.expectPlanPreview('Scratch week');

      await gym.openDayByTitle('Day 1');
      await gym.tapText('Start workout');
      await gym.awaitLiveLogger();
      await gym.tapLogSet();
      await gym.endAndDiscard();
      await gym.returnToPlansHome();
      expect($('Continue workout'), findsNothing);
    },
  );
}
