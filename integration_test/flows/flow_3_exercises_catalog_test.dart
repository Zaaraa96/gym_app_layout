import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '3 catalog: Exercises tab filters bundled movements and opens add',
    ($, gym) async {
      await gym.waitForWelcome();
      await gym.tapText(
        'Create a plan',
        settle: SettlePolicy.noSettle,
      );
      await gym.pumpQuiet(const Duration(milliseconds: 600));
      await gym.expectVisible('Create plan');
      await gym.back();
      await gym.pumpQuiet(const Duration(milliseconds: 600));
      expect($('Untitled plan'), findsWidgets);

      await gym.openExercisesTab();
      expect($('Search'), findsWidgets);
      expect($(const Key('region-all')), findsOneWidget);
      expect($(const Key('region-abs')), findsOneWidget);
      expect($(const Key('region-upper')), findsOneWidget);
      expect($(const Key('region-lower')), findsOneWidget);
      expect($(const Key('region-cardio')), findsOneWidget);
      expect($(const Key('add-catalog-exercise')), findsOneWidget);

      await $(const Key('catalog-search')).enterText('plank');
      await gym.pumpQuiet();
      await gym.hideKeyboard();
      await gym.expectVisible(const Key('catalog-tile-plank'));
      expect($(const Key('catalog-tile-squat')), findsNothing);

      await gym.tapKey('catalog-tile-plank');
      await gym.expectVisible('Plank');
      expect($(const Key('edit-catalog-exercise')), findsNothing);
      expect($(const Key('delete-catalog-exercise')), findsNothing);
      await gym.back();

      await $(const Key('catalog-search')).enterText('');
      await gym.pumpQuiet();
      await gym.tapKey('region-abs');
      await $(const Key('catalog-search')).enterText('squat');
      await gym.pumpQuiet();
      expect($(const Key('catalog-tile-squat')), findsNothing);
      await $(const Key('catalog-search')).enterText('plank');
      await gym.pumpQuiet();
      await gym.hideKeyboard();
      await gym.expectVisible(const Key('catalog-tile-plank'));

      await gym.tapKey('add-catalog-exercise');
      await gym.expectVisible(const Key('catalog-exercise-name'));
      expect($('Tap to add a picture'), findsOneWidget);
      await gym.back();
      await gym.expectVisible(const Key('exercises-tab'));
    },
  );
}
