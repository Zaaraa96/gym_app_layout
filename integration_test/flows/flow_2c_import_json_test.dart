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
      await gym.expectVisible(RegExp('Create plan'));
      await gym.expectVisible(RegExp('didn’t go as planned'));
      await gym.back();

      await gym.tapText('Import', settle: SettlePolicy.noSettle);
      await gym.pickJsonFromDownloads('valid-plan.json');
      await gym.expectVisible('Create plan');
      expect($('plan 1'), findsWidgets);
      await gym.tapText('Finish plan');
      await gym.expectVisible('plan 1');
      expect($('day 1- 4sar'), findsOneWidget);
    },
  );
}
