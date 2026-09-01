import 'json_plan_importer.dart';
import 'models/models.dart';
import 'plan_import_picker.dart';
import 'plan_repository.dart';

/// Result of picking a file and turning it into a [WorkoutPlan].
sealed class PlanImportOutcome {
  const PlanImportOutcome();
}

final class PlanImportCancelled extends PlanImportOutcome {
  const PlanImportCancelled();
}

final class PlanImportFailed extends PlanImportOutcome {
  const PlanImportFailed(this.message);

  /// Safe to show in a snackbar.
  final String message;
}

final class PlanImportParsed extends PlanImportOutcome {
  const PlanImportParsed({required this.fileName, required this.plan});

  final String fileName;
  final WorkoutPlan plan;
}

/// Pick JSON → validate → save. Widgets call one method and render.
class PlanImport {
  PlanImport({
    this.picker,
    required this.plans,
    this.importer = const JsonPlanImporter(),
  });

  final PlanImportPicker? picker;
  final PlanRepository plans;
  final JsonPlanImporter importer;

  Future<PlanImportOutcome> pickAndParse() async {
    final picker = this.picker;
    if (picker == null) {
      throw StateError('PlanImport.pickAndParse needs a picker');
    }
    final PickedPlanFile? picked;
    try {
      picked = await picker.pick();
    } catch (error) {
      return PlanImportFailed(
        error is PlanImportException
            ? error.message
            : 'Could not open a file: $error',
      );
    }
    if (picked == null) return const PlanImportCancelled();

    try {
      return PlanImportParsed(
        fileName: picked.fileName,
        plan: importer.import(picked.contents),
      );
    } on PlanImportException catch (error) {
      return PlanImportFailed(error.message);
    }
  }

  Future<WorkoutPlan> save(WorkoutPlan plan) async {
    plan.id = await plans.save(plan);
    return plan;
  }
}
