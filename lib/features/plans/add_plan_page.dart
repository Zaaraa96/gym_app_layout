import 'package:flutter/material.dart';

import '../../data/app_ports.dart';
import '../../domain/plan_import_issue.dart';
import 'plan_builder_page.dart';

/// Welcome/Plans "Create a plan" / "New" land on the stepper builder.
class AddNewPlanPage extends StatelessWidget {
  const AddNewPlanPage({
    super.key,
    required this.ports,
    this.planId,
    this.importIssues = const [],
  });

  final AppPorts ports;
  final String? planId;
  final List<PlanImportIssue> importIssues;

  @override
  Widget build(BuildContext context) {
    return PlanBuilderPage(
      ports: ports,
      planId: planId,
      importIssues: importIssues,
    );
  }
}
