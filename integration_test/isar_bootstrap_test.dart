import 'package:integration_test/integration_test.dart';

import '../test/data/isar_bootstrap_test.dart' as isar_bootstrap;

/// Device-runner for the Step 1 Isar bootstrap test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  isar_bootstrap.main();
}
