import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/plan_import_picker.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_lifecycle.dart';
import 'package:gym_app/data/session_repository.dart';

AppPorts testPorts({
  PlanRepository? plans,
  SessionRepository? sessions,
  SessionLifecycle? lifecycle,
  PlanImportPicker? picker,
}) {
  return AppPorts(
    plans: plans ?? MemoryPlanRepository(),
    sessions: sessions ?? MemorySessionRepository(),
    lifecycle: lifecycle,
    picker: picker,
  );
}
