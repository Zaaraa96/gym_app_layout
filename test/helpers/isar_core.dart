import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// Host tests download the native binary. Device runs already have it from
/// `isar_flutter_libs`.
///
/// [IsarError] means the library is already loaded. Anything else (network,
/// permissions) fails here instead of looking like a later [Isar.open] bug.
Future<void> ensureIsarCore() async {
  try {
    await Isar.initializeIsarCore(download: true);
  } on IsarError {
    // Already loaded for this process.
  } catch (error, stack) {
    fail('Could not load the Isar native library: $error\n$stack');
  }
}
