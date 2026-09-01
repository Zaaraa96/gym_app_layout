import 'plan_import.dart';
import 'plan_import_picker.dart';
import 'plan_repository.dart';
import 'session_lifecycle.dart';
import 'session_repository.dart';
import 'start_session.dart';

/// Ports the UI may use. Composition root builds this; pages take it.
class AppPorts {
  AppPorts({
    required this.plans,
    required this.sessions,
    SessionLifecycle? lifecycle,
    PlanImportPicker? picker,
  }) : lifecycle = lifecycle ?? SessionLifecycle(sessions) {
    startSession = StartSession(this.lifecycle, sessions);
    planImport = PlanImport(plans: plans, picker: picker);
  }

  final PlanRepository plans;
  final SessionRepository sessions;
  final SessionLifecycle lifecycle;
  late final StartSession startSession;
  late final PlanImport planImport;
}
