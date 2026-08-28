import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'common/app_routes.dart';
import 'common/app_theme.dart';
import 'data/isar_service.dart';
import 'data/plan_repository.dart';
import 'data/session_repository.dart';
import 'features/plans/add_plan_page.dart';
import 'features/plans/day_editor_page.dart';
import 'features/plans/day_preview_page.dart';
import 'features/plans/import_preview_page.dart';
import 'features/plans/plan_import_picker.dart';
import 'features/plans/plan_page.dart';
import 'features/plans/plans_home_page.dart';
import 'features/plans/starter_plans_page.dart';
import 'features/welcome/welcome_page.dart';
import 'features/workout/live_workout_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarService = Get.put(await IsarService.init());
  final plans = Get.put(PlanRepository(isarService.isar));
  Get.put(SessionRepository(isarService.isar));
  Get.put<PlanImportPicker>(FilePickerPlanImportPicker());
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
        GetPage(name: AppRoutes.starters, page: () => const StarterPlansPage()),
        GetPage(
          name: AppRoutes.import,
          page: () {
            final args = Get.arguments as ImportPreviewArgs;
            return ImportPreviewPage(fileName: args.fileName, plan: args.plan);
          },
        ),
        GetPage(name: AppRoutes.newPlan, page: () => const AddNewPlanPage()),
        GetPage(
          name: AppRoutes.plan,
          page: () => PlanPage(planId: Get.arguments as int),
        ),
        GetPage(
          name: AppRoutes.day,
          page: () {
            final args = Get.arguments as DayPreviewArgs;
            return DayPreviewPage(planId: args.planId, dayId: args.dayId);
          },
        ),
        GetPage(
          name: AppRoutes.editDay,
          page: () {
            final args = Get.arguments as DayEditorArgs;
            return DayEditorPage(planId: args.planId, dayId: args.dayId);
          },
        ),
        GetPage(
          name: AppRoutes.editSection,
          page: () {
            final args = Get.arguments as DayEditorArgs;
            return DayEditorPage(
              planId: args.planId,
              sectionId: args.sectionId,
            );
          },
        ),
        GetPage(
          name: AppRoutes.session,
          page: () => LiveWorkoutPage(sessionId: Get.arguments as int),
        ),
      ],
    );
  }
}
