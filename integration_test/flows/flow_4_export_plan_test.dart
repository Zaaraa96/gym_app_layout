import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '4 export: plan overflow offers Full package and Lite, then cancel',
    ($, gym) async {
      await gym.installFullBodyFromWelcome();
      await gym.openPlan(GymApp.fullBodyTitle);
      await gym.openExportDialog();
      expect($('Full package'), findsOneWidget);
      expect($('Lite'), findsOneWidget);
      expect(
        $(
          'Full includes your photos, GIFs, and short videos. '
          'Lite is JSON only. Workouts on Month stay on this device.',
        ),
        findsOneWidget,
      );
      await gym.tapText('Cancel');
      await gym.expectPlanPreview(GymApp.fullBodyTitle);
    },
  );
}
