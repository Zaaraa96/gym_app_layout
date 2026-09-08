import 'plan_export.dart';
import 'plan_import.dart';
import 'plan_import_picker.dart';
import 'plan_package_share.dart';
import '../domain/plan_repository.dart';
import '../domain/session_lifecycle.dart';
import '../domain/session_repository.dart';
import '../domain/start_session.dart';

/// Ports the UI may use. Composition root builds this; pages take it.
class AppPorts {
  AppPorts({
    required this.plans,
    required this.sessions,
    SessionLifecycle? lifecycle,
    PlanImportPicker? picker,
    PlanPackageShare? packageShare,
  }) : lifecycle = lifecycle ?? SessionLifecycle(sessions) {
    startSession = StartSession(this.lifecycle, sessions);
    planImport = PlanImport(plans: plans, picker: picker);
    planExport = PlanExport(share: packageShare);
  }

  final PlanRepository plans;
  final SessionRepository sessions;
  final SessionLifecycle lifecycle;
  late final StartSession startSession;
  late final PlanImport planImport;
  late final PlanExport planExport;
}
