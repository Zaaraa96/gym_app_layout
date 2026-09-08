import '../domain/models/models.dart';
import 'plan_package_exporter.dart';
import 'plan_package_share.dart';

sealed class PlanExportOutcome {
  const PlanExportOutcome();
}

final class PlanExportCancelled extends PlanExportOutcome {
  const PlanExportCancelled();
}

final class PlanExportFailed extends PlanExportOutcome {
  const PlanExportFailed(this.message);
  final String message;
}

final class PlanExportShared extends PlanExportOutcome {
  const PlanExportShared({this.warnings = const []});
  final List<String> warnings;
}

/// Build a package and hand it to [PlanPackageShare].
class PlanExport {
  PlanExport({
    PlanPackageExporter? exporter,
    PlanPackageShare? share,
  })  : exporter = exporter ?? const PlanPackageExporter(),
        share = share ?? PlatformPlanPackageShare();

  final PlanPackageExporter exporter;
  final PlanPackageShare share;

  Future<PlanExportOutcome> export(
    WorkoutPlan plan, {
    required bool lite,
  }) async {
    try {
      final built = lite
          ? exporter.exportJson(plan)
          : await exporter.exportZip(plan);
      final ok = await share.share(
        fileName: built.fileName,
        bytes: built.bytes,
      );
      if (!ok) return const PlanExportCancelled();
      return PlanExportShared(warnings: built.warnings);
    } catch (error) {
      return PlanExportFailed('Could not export this plan: $error');
    }
  }
}
