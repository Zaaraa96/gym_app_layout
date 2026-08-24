import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'common/app_routes.dart';
import 'common/app_theme.dart';
import 'data/isar_service.dart';
import 'data/plan_repository.dart';
import 'features/add_plan_page.dart';
import 'features/plans/plans_home_page.dart';
import 'features/welcome/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarService = Get.put(await IsarService.init());
  final plans = Get.put(PlanRepository(isarService.isar));
  runApp(MyApp(initialRoute: await resolveInitialRoute(plans)));
}

/// Welcome is a first-run screen: skip it once any plan is stored.
Future<String> resolveInitialRoute(PlanRepository plans) async =>
    await plans.count() > 0 ? AppRoutes.home : AppRoutes.welcome;

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = AppRoutes.welcome});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My Awesome Gym App',
      theme: appTheme,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: AppRoutes.welcome, page: () => const WelcomePage()),
        GetPage(name: AppRoutes.home, page: () => const PlansHomePage()),
        GetPage(name: AppRoutes.newPlan, page: () => const AddNewPlanPage()),
      ],
    );
  }
}
