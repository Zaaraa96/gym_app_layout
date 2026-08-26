import 'package:integration_test/integration_test.dart';

import '../test/features/json_import_test.dart' as json_import;

/// Device-runner for the Step 3 JSON import test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  json_import.main();
}
