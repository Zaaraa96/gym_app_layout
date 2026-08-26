import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';

/// First-run fork: get a plan in by import or by creating one.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
                'Start with a plan. Import one you already have, or build it here.',
                style: subtitleTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppElevatedButton(
                  data: 'Import a plan',
                  onPressed: () => showImportComingSoon(context),
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

/// JSON import lands in the next slice; until then say so instead of dead-ending.
void showImportComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('JSON import is coming next')),
  );
}
