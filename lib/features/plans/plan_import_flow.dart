import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../data/plan_import.dart';
import 'plan_builder_page.dart';

/// Pick a plan package or JSON, salvage it, and open Create plan as a draft.
///
/// Cancel leaves the current screen. Unreadable files stay here with a snackbar.
Future<void> startPlanImport(
  BuildContext context, {
  required PlanImport import,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    case PlanImportParsed(:final plan, :final issues):
      ScaffoldMessenger.of(context).clearSnackBars();
      await import.save(plan);
      if (!context.mounted) return;
      await Get.toNamed(
        AppRoutes.newPlan,
        arguments: PlanBuilderArgs(
          planId: plan.uuid,
          importIssues: issues,
        ),
      );
  }
}
