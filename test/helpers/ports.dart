import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/memory_catalog_repository.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/plan_import_picker.dart';
import 'package:gym_app/domain/catalog_repository.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_lifecycle.dart';
import 'package:gym_app/domain/session_repository.dart';

AppPorts testPorts({
  PlanRepository? plans,
  SessionRepository? sessions,
  CatalogRepository? catalog,
  SessionLifecycle? lifecycle,
  PlanImportPicker? picker,
}) {
  return AppPorts(
    plans: plans ?? MemoryPlanRepository(),
    sessions: sessions ?? MemorySessionRepository(),
    catalog: catalog ?? MemoryCatalogRepository(),
    lifecycle: lifecycle,
    picker: picker,
  );
}
