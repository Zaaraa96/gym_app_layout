import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../data/app_ports.dart';
import '../../data/plan_import.dart';
import 'import_preview_page.dart';

/// Pick a JSON file, parse it, and open the import preview.
///
/// Cancel leaves the current screen. Parse errors stay here with a snackbar.
Future<void> startPlanImport(
  BuildContext context, {
  required PlanImport import,
  AppPorts? ports,
}) async {
  if (context.mounted) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  final outcome = await import.pickAndParse();
  if (!context.mounted) return;

  switch (outcome) {
    case PlanImportCancelled():
      return;
    case PlanImportFailed(:final message):
      _showError(context, message);
    case PlanImportParsed(:final fileName, :final plan):
      ScaffoldMessenger.of(context).clearSnackBars();
      if (ports != null) {
        await Get.to(
          () => ImportPreviewPage(
            fileName: fileName,
            plan: plan,
            ports: ports,
          ),
          routeName: AppRoutes.import,
        );
      } else {
        await Get.toNamed(
          AppRoutes.import,
          arguments: ImportPreviewArgs(fileName: fileName, plan: plan),
        );
      }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
