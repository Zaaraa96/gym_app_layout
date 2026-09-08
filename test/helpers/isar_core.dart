import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/isar_catalog_repository.dart';
import 'package:gym_app/data/isar_plan_repository.dart';
import 'package:gym_app/data/isar_session_repository.dart';
import 'package:gym_app/data/plan_import_picker.dart';
import 'package:gym_app/domain/catalog_repository.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_lifecycle.dart';
import 'package:gym_app/domain/session_repository.dart';
import 'package:isar/isar.dart';

/// Host tests download the native binary. Device runs already have it from
/// `isar_flutter_libs`.
///
/// [IsarError] means the library is already loaded. Anything else (network,
/// permissions) fails here instead of looking like a later [Isar.open] bug.
Future<void> ensureIsarCore() async {
  final bundled = _copyBundledLinuxIsarIfNeeded();
  try {
    await Isar.initializeIsarCore(download: !bundled);
  } on IsarError {
    // Already loaded for this process.
  } catch (error, stack) {
    fail('Could not load the Isar native library: $error\n$stack');
  }
}

bool _copyBundledLinuxIsarIfNeeded() {
  if (!Platform.isLinux) return false;
  final dest = File('${Directory.current.path}/libisar.so');
  if (dest.existsSync()) return true;
  final home = Platform.environment['HOME'] ?? '';
  final bundled = File(
    '$home/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/linux/libisar.so',
  );
  if (!bundled.existsSync()) return false;
  bundled.copySync(dest.path);
  return true;
}

PlanRepository putPlans(Isar isar) {
  final plans = Get.put<PlanRepository>(
    IsarPlanRepository(isar),
    permanent: true,
  );
  _putAppPorts();
  return plans;
}

SessionRepository putSessions(Isar isar) {
  final sessions = Get.put<SessionRepository>(
    IsarSessionRepository(isar),
    permanent: true,
  );
  Get.put(SessionLifecycle(sessions), permanent: true);
  _putAppPorts();
  return sessions;
}

CatalogRepository putCatalog(Isar isar) {
  final catalog = Get.put<CatalogRepository>(
    IsarCatalogRepository(isar),
    permanent: true,
  );
  _putAppPorts();
  return catalog;
}

void _putAppPorts() {
  if (!Get.isRegistered<PlanRepository>() ||
      !Get.isRegistered<SessionRepository>()) {
    return;
  }
  Get.put(
    AppPorts(
      plans: Get.find<PlanRepository>(),
      sessions: Get.find<SessionRepository>(),
      catalog: Get.isRegistered<CatalogRepository>()
          ? Get.find<CatalogRepository>()
          : null,
      lifecycle: Get.isRegistered<SessionLifecycle>()
          ? Get.find<SessionLifecycle>()
          : null,
      picker: Get.isRegistered<PlanImportPicker>()
          ? Get.find<PlanImportPicker>()
          : null,
    ),
    permanent: true,
  );
}

/// Finish a GetX page transition and let a real Isar read land.
///
/// `pumpAndSettle` is unusable on Welcome: the Lottie never stops.
/// One frame of `pump()` only advances ~16ms, so 12 frames leave the
/// incoming route mid-slide and AppBar actions sit past the 800px view.
/// Starting a session does an extra in-progress read plus a write, then the
/// live page reads again, so we yield to the host more times than a single
/// Isar hop needs.
Future<void> settleApp(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  for (var i = 0; i < 24; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
