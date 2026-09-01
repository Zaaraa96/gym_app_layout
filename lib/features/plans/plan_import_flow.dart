import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../data/plan_import.dart';
import '../../data/plan_repository.dart';
import 'import_preview_page.dart';
import 'plan_import_picker.dart';

/// Pick a JSON file, parse it, and open the import preview.
///
/// Cancel leaves the current screen. Parse errors stay here with a snackbar.
Future<void> startPlanImport(
  BuildContext context, {
  PlanImport? import,
}) async {
  final flow = import ??
      PlanImport(
        picker: Get.isRegistered<PlanImportPicker>()
            ? Get.find<PlanImportPicker>()
            : FilePickerPlanImportPicker(),
        plans: Get.find<PlanRepository>(),
      );

  if (context.mounted) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  final outcome = await flow.pickAndParse();
  if (!context.mounted) return;

  switch (outcome) {
    case PlanImportCancelled():
      return;
    case PlanImportFailed(:final message):
      _showError(context, message);
    case PlanImportParsed(:final fileName, :final plan):
      ScaffoldMessenger.of(context).clearSnackBars();
      await Get.toNamed(
        AppRoutes.import,
        arguments: ImportPreviewArgs(fileName: fileName, plan: plan),
      );
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
