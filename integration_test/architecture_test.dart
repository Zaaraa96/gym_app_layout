import 'package:integration_test/integration_test.dart';

import '../test/data/session_repository_test.dart' as sessions;
import '../test/features/progress_service_test.dart' as progress;
import '../test/features/workout_controller_test.dart' as workout;

/// Device-runner for the Step 4 architecture tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sessions.main();
  workout.main();
  progress.main();
}
