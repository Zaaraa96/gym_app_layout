import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '1 + 2a: Welcome, beginner full body, same title reused, delete plan',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.openBeginnerFromWelcome();
      expect($(GymApp.fullBodyTitle), findsOneWidget);
      expect($(GymApp.twoDayTitle), findsOneWidget);
      expect($('Recommended'), findsOneWidget);

      await gym.useStarterFullBody();
      await gym.expectPlansHomeWith(GymApp.fullBodyTitle);
      expect($('Today: Day 1 — Squat and push'), findsOneWidget);
      expect($("Start today's workout"), findsOneWidget);
      expect($('Beginner'), findsOneWidget);

      await gym.openStartersFromHome();
      await gym.useStarterFullBody();
      expect($(GymApp.fullBodyTitle), findsOneWidget);
      expect($('3 days'), findsOneWidget);

      await gym.openPlan(GymApp.fullBodyTitle);
      await gym.deleteOpenPlan();
      await gym.expectVisible(
        'No plans yet. Start with a beginner template, import one, or create your first.',
      );
      expect($(const Key('open-starters')), findsOneWidget);
      expect($('Start with a beginner plan'), findsOneWidget);
    },
  );
}
