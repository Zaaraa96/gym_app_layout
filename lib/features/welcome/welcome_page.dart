import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/app_theme.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/cuelift_brand.dart';
import '../../common/widgets/theme_mode_button.dart';
import '../../data/app_ports.dart';
import '../plans/plan_import_flow.dart';

/// First-run fork: get a plan in by starter, import, or create.
///
/// Always uses the navy Welcome brand field (design-system Welcome rule).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.ports});

  final AppPorts ports;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: welcomeBrandTheme(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: CueLiftColors.navy,
        ),
        child: AppScaffold(
          backgroundColor: CueLiftColors.navy,
          appbar: AppBar(
            backgroundColor: CueLiftColors.navy,
            foregroundColor: CueLiftColors.white,
            title: const Text(''),
            actions: const [
              ThemeModeButton(),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CueLiftWelcomeBrand(height: 260),
                  const SizedBox(height: 28),
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
        ),
      ),
    );
  }
}
