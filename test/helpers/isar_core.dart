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

/// Finish a GetX page transition and let a real Isar read land.
///
/// `pumpAndSettle` is unusable on Welcome: the Lottie never stops.
/// One frame of `pump()` only advances ~16ms, so 12 frames leave the
/// incoming route mid-slide and AppBar actions sit past the 800px view.
Future<void> settleApp(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
