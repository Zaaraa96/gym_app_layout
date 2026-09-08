import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2c: native picker salvages broken JSON then Finish plan on plan.json',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.tapText(
        'Import a plan',
        settle: SettlePolicy.noSettle,
      );
      await gym.pickFileFromDownloads('broken.json');
      await gym.expectVisible('Create plan');
      await gym.expectImportIssuesBanner();
      await gym.back();

      await gym.tapText('Import', settle: SettlePolicy.noSettle);
      await gym.pickFileFromDownloads('valid-plan.json');
      await gym.expectVisible('Create plan');
      expect($('plan 1'), findsWidgets);
      expect($('day 1- 4sar'), findsWidgets);
      expect($('abs'), findsWidgets);
      expect($('corrective'), findsWidgets);
      await gym.finishImportedPlan('plan 1');
      expect($('day 1- 4sar'), findsOneWidget);
      expect($('abs'), findsOneWidget);
      expect($('corrective'), findsOneWidget);
    },
  );
}
