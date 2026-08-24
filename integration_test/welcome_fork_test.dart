import 'package:integration_test/integration_test.dart';

import '../test/features/welcome_fork_test.dart' as welcome_fork;

/// Device-runner for the Step 2 welcome/home fork test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  welcome_fork.main();
}
