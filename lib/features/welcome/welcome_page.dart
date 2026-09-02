import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/app_ports.dart';
import '../plans/plan_import_flow.dart';

/// First-run fork: get a plan in by starter, import, or create.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.ports});

  final AppPorts ports;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/json/gym.json', height: 240),
              AppText(
                'Welcome To the Amazing Gym app',
                style: titleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const AppText(
                'Start with a plan. Grab a beginner template, import one you '
                'already have, or build it here.',
                style: subtitleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppElevatedButton(
                  data: 'Start with a beginner plan',
                  onPressed: () => Get.toNamed(AppRoutes.starters),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppElevatedButton(
                  outlined: true,
                  data: 'Import a plan',
                  onPressed: () => startPlanImport(
                    context,
                    import: ports.planImport,
                    ports: ports,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppElevatedButton(
                  outlined: true,
                  data: 'Create a plan',
                  onPressed: () => Get.toNamed(AppRoutes.newPlan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
