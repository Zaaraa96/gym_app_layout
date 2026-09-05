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
      await gym.pickJsonFromDownloads('invalid-plan.json');
      expect($(RegExp('not valid JSON')), findsOneWidget);

      await gym.tapText('Import a plan', settle: SettlePolicy.noSettle);
      await gym.pickJsonFromDownloads('plan.json');
      await gym.expectVisible('Import preview');
      expect($('plan 1'), findsOneWidget);
      await gym.tapText('Save plan');
      await gym.expectVisible('plan 1');
      expect($('day 1- 4sar'), findsOneWidget);
    },
  );
}
