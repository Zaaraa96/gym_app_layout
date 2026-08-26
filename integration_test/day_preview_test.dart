import 'package:integration_test/integration_test.dart';

import '../test/features/day_preview_test.dart' as day_preview;

/// Device-runner for the Step 4 plan/day preview test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  day_preview.main();
}
