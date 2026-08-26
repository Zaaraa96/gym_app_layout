import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../data/json_plan_importer.dart';
import 'import_preview_page.dart';
import 'plan_import_picker.dart';

/// Pick a JSON file, parse it, and open the import preview.
///
/// Cancel leaves the current screen. Parse errors stay here with a snackbar.
Future<void> startPlanImport(BuildContext context) async {
  final picker = Get.isRegistered<PlanImportPicker>()
      ? Get.find<PlanImportPicker>()
      : FilePickerPlanImportPicker();

  final PickedPlanFile? picked;
  try {
    picked = await picker.pick();
  } catch (error) {
    if (!context.mounted) return;
    _showError(
      context,
      error is PlanImportException
          ? error.message
          : 'Could not open a file: $error',
    );
    return;
  }
  if (picked == null) return;

  try {
    final plan = const JsonPlanImporter().import(picked.contents);
    if (!context.mounted) return;
    await Get.toNamed(
      AppRoutes.import,
      arguments: ImportPreviewArgs(fileName: picked.fileName, plan: plan),
    );
  } on PlanImportException catch (error) {
    if (!context.mounted) return;
    _showError(context, error.message);
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
