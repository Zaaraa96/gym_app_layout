import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../common/app_routes.dart';
import '../common/app_theme.dart';
import '../common/widgets/app_load_error.dart';
import '../common/widgets/app_scaffold.dart';
import '../data/app_ports.dart';
import '../data/isar_plan_repository.dart';
import '../data/isar_service.dart';
import '../data/isar_session_repository.dart';
import '../data/memory_plan_repository.dart';
import '../data/memory_session_repository.dart';
import '../data/remote/http_remote_plan_data_source.dart';
import '../data/remote/http_remote_session_data_source.dart';
import '../data/remote/remote_plan_data_source.dart';
import '../data/remote/remote_session_data_source.dart';
import '../data/sync/sync_service.dart';
import '../domain/plan_repository.dart';
import '../domain/session_lifecycle.dart';
import '../domain/session_repository.dart';
import '../features/plans/exercise_media_picker.dart';
import '../features/plans/plan_import_picker.dart';
import 'app_routes.dart';

/// Opens local storage, registers repositories, and picks welcome vs home.
Future<String> bootApp() async {
  late final PlanRepository plans;
  late final SessionRepository sessions;
  if (kIsWeb) {
    // Isar 3.1 refuses to open on web (`openIsar` throws). Keep the same
    // repository interfaces so the UI does not change.
    plans = Get.put<PlanRepository>(MemoryPlanRepository());
    sessions = Get.put<SessionRepository>(MemorySessionRepository());
  } else {
    final isarService = Get.put(await IsarService.init());
    plans = Get.put<PlanRepository>(
      IsarPlanRepository(isarService.isar),
    );
    sessions = Get.put<SessionRepository>(
      IsarSessionRepository(isarService.isar),
    );
  }
  Get.put(SessionLifecycle(sessions));
  final picker = FilePickerPlanImportPicker();
  Get.put<PlanImportPicker>(picker);
  Get.put(
    AppPorts(
      plans: plans,
      sessions: sessions,
      lifecycle: Get.find<SessionLifecycle>(),
      picker: picker,
    ),
  );
  _registerSync(plans, sessions);
  Get.put<ExerciseGalleryPicker>(ImagePickerExerciseGalleryPicker());
  return resolveInitialRoute(plans);
}

/// Themed loader (then [MyApp]) so launch is never an empty black surface.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, this.boot = bootApp});

  final Future<String> Function() boot;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  String? _route;
  String? _error;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final generation = ++_generation;
    if (_error != null || _route != null) {
      setState(() {
        _error = null;
        _route = null;
      });
    }
    try {
      final route = await widget.boot();
      if (!mounted || generation != _generation) return;
      setState(() => _route = route);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = 'Could not open the app. $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    if (route != null) {
      return MyApp(initialRoute: route);
    }
    return MaterialApp(
      title: 'My Awesome Gym App',
      theme: appTheme,
      home: AppScaffold(
        body: _error == null
            ? const Center(
                child: CircularProgressIndicator(key: Key('app-boot')),
              )
            : AppLoadError(message: _error!, onRetry: _start),
      ),
    );
  }
}

/// Compile with `--dart-define=API_BASE_URL=https://host` to enable HTTP sync.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void _registerSync(PlanRepository plans, SessionRepository sessions) {
  final enabled = apiBaseUrl.isNotEmpty;
  final client = http.Client();
  final remotePlans = enabled
      ? HttpRemotePlanDataSource(baseUrl: apiBaseUrl, client: client)
      : const NoopRemotePlanDataSource();
  final remoteSessions = enabled
      ? HttpRemoteSessionDataSource(baseUrl: apiBaseUrl, client: client)
      : const NoopRemoteSessionDataSource();
  final sync = Get.put(
    SyncService(
      plans: plans,
      sessions: sessions,
      remotePlans: remotePlans,
      remoteSessions: remoteSessions,
      enabled: enabled,
    ),
  );
  if (enabled) {
    plans.watch().listen((_) => sync.sync());
    sessions.watch().listen((_) => sync.sync());
    sync.sync();
  }
}

/// Welcome is a first-run screen: skip it once any plan is stored.
Future<String> resolveInitialRoute(PlanRepository plans) async =>
    await plans.count() > 0 ? AppRoutes.home : AppRoutes.welcome;
