import 'package:flutter_test/flutter_test.dart';

import 'support/gym_app.dart';

void main() {
  gymPatrolTest(
    '2c gymplan: native picker opens a package as a Create plan draft',
    ($, gym) async {
      await gym.waitForWelcome();

      await gym.tapText(
        'Import a plan',
        settle: SettlePolicy.noSettle,
      );
      // DocumentsUI's Downloads collection keeps adb-pushed `*.gymplan` as
      // application/octet-stream and often hides the row. Same zip bytes as a
      // .gymplan package; unit tests cover the .gymplan extension.
      await gym.pickFileFromDownloads('pack.zip');
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
