import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2c: native picker rejects invalid JSON then saves plan.json',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.tapText(
        'Import a plan',
        settle: SettlePolicy.noSettle,
      );
      await gym.pickJsonFromDownloads('broken.json');
      await gym.expectVisible(RegExp('not valid JSON'));

      await gym.tapText('Import a plan', settle: SettlePolicy.noSettle);
      await gym.pickJsonFromDownloads('valid-plan.json');
      await gym.expectVisible('Import preview');
      expect($('plan 1'), findsOneWidget);
      expect($('Former common sections'), findsOneWidget);
      expect($('abs'), findsWidgets);
      expect($('corrective'), findsWidgets);
      await gym.tapText('Save plan');
      await gym.expectPlanPreview('plan 1');
      expect($('day 1- 4sar'), findsOneWidget);
      expect($('abs'), findsOneWidget);
      expect($('corrective'), findsOneWidget);
    },
  );
}
