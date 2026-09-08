import 'json_plan_importer.dart';
import '../domain/models/models.dart';
import '../domain/plan_import_issue.dart';
import 'plan_import_picker.dart';
import 'plan_package_importer.dart';
import 'exercise_media_store.dart';
import '../domain/plan_repository.dart';

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
  const PlanImportParsed({
    required this.fileName,
    required this.plan,
    this.convertedCommonSectionTitles = const [],
    this.issues = const [],
  });

  final String fileName;
  final WorkoutPlan plan;
  final List<String> convertedCommonSectionTitles;
  final List<PlanImportIssue> issues;
}

/// Pick a package or JSON → salvage → save as a draft.
class PlanImport {
  PlanImport({
    this.picker,
    required this.plans,
    this.importer = const JsonPlanImporter(),
    PlanPackageImporter? packages,
    ExerciseMediaStore? mediaStore,
  }) : packages = packages ??
            PlanPackageImporter(
              jsonImporter: importer,
              mediaStore: mediaStore ?? ExerciseMediaStore(),
            );

  final PlanImportPicker? picker;
  final PlanRepository plans;
  final JsonPlanImporter importer;
  final PlanPackageImporter packages;

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
      final imported = await packages.importBytes(
        picked.data,
        fileName: picked.fileName,
      );
      imported.plan.status = PlanStatus.draft;
      imported.plan.source = PlanSource.imported;
      return PlanImportParsed(
        fileName: picked.fileName,
        plan: imported.plan,
        convertedCommonSectionTitles: imported.convertedCommonSectionTitles,
        issues: imported.issues,
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
