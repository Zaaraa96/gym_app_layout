import 'package:flutter/material.dart';

import '../../data/app_ports.dart';
import 'plan_builder_page.dart';

/// Welcome/Plans "Create a plan" / "New" land on the stepper builder.
class AddNewPlanPage extends StatelessWidget {
  const AddNewPlanPage({super.key, required this.ports, this.planId});

  final AppPorts ports;
  final String? planId;

  @override
  Widget build(BuildContext context) {
    return PlanBuilderPage(ports: ports, planId: planId);
  }
}
