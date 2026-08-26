import 'package:integration_test/integration_test.dart';

import '../test/features/add_plan_test.dart' as add_plan;
import '../test/features/plan_editor_test.dart' as plan_editor;

/// Device-runner for the Step 5 create/edit plan tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  add_plan.main();
  plan_editor.main();
}
