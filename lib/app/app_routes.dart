import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/app_routes.dart';
import '../common/app_theme.dart';
import '../common/theme_controller.dart';
import '../data/app_ports.dart';
import '../domain/catalog_repository.dart';
import '../domain/plan_repository.dart';
import '../domain/session_lifecycle.dart';
import '../domain/session_repository.dart';
import '../features/catalog/catalog_exercise_detail_page.dart';
import '../features/catalog/catalog_exercise_editor_page.dart';
import '../features/plans/add_plan_page.dart';
import '../features/plans/day_editor_page.dart';
import '../features/plans/day_preview_page.dart';
import '../features/plans/exercise_media_picker.dart';
import '../features/plans/exercise_media_picker_sheet.dart';
import '../features/plans/plan_builder_page.dart';
import '../features/plans/plan_import_picker.dart';
import '../features/plans/plan_page.dart';
import '../features/plans/plans_home_page.dart';
import '../features/plans/starter_plans_page.dart';
import '../features/progress/session_log_page.dart';
import '../features/welcome/welcome_page.dart';
import '../features/workout/live_workout_page.dart';

AppPorts resolveAppPorts() {
  return AppPorts(
    plans: Get.find<PlanRepository>(),
    sessions: Get.find<SessionRepository>(),
    catalog: Get.isRegistered<CatalogRepository>()
        ? Get.find<CatalogRepository>()
        : null,
    lifecycle: Get.isRegistered<SessionLifecycle>()
        ? Get.find<SessionLifecycle>()
        : null,
    picker: Get.isRegistered<PlanImportPicker>()
        ? Get.find<PlanImportPicker>()
        : null,
  );
}

/// GetX page table. Route names live in [AppRoutes].
List<GetPage<dynamic>> appPages() => [
      GetPage(
        name: AppRoutes.welcome,
        page: () => WelcomePage(ports: resolveAppPorts()),
      ),
      GetPage(
        name: AppRoutes.home,
        page: () => PlansHomePage(ports: resolveAppPorts()),
      ),
      GetPage(
        name: AppRoutes.catalogExercise,
        page: () => CatalogExerciseDetailPage(
          exerciseId: Get.arguments as String,
          ports: resolveAppPorts(),
        ),
      ),
      GetPage(
        name: AppRoutes.editCatalogExercise,
        page: () => CatalogExerciseEditorPage(
          ports: resolveAppPorts(),
          exerciseId: Get.arguments is String ? Get.arguments as String : null,
        ),
      ),
      GetPage(
        name: AppRoutes.starters,
        page: () => StarterPlansPage(ports: resolveAppPorts()),
      ),
      GetPage(
        name: AppRoutes.newPlan,
        page: () {
          final args = PlanBuilderArgs.from(Get.arguments);
          return AddNewPlanPage(
            ports: resolveAppPorts(),
            planId: args.planId,
            importIssues: args.importIssues,
          );
        },
      ),
      GetPage(
        name: AppRoutes.plan,
        page: () => PlanPage(
          planId: Get.arguments as String,
          ports: resolveAppPorts(),
        ),
      ),
      GetPage(
        name: AppRoutes.day,
        page: () {
          final args = Get.arguments as DayPreviewArgs;
          return DayPreviewPage(
            planId: args.planId,
            dayId: args.dayId,
            ports: resolveAppPorts(),
          );
        },
      ),
      GetPage(
        name: AppRoutes.editDay,
        page: () {
          final args = Get.arguments as DayEditorArgs;
          return DayEditorPage(
            planId: args.planId,
            dayId: args.dayId,
            ports: resolveAppPorts(),
          );
        },
      ),
      GetPage(
        name: AppRoutes.session,
        page: () => LiveWorkoutPage(
          sessionId: Get.arguments as String,
          ports: resolveAppPorts(),
        ),
      ),
      GetPage(
        name: AppRoutes.dayLog,
        page: () => DayLogPage(
          day: Get.arguments as DateTime,
          ports: resolveAppPorts(),
        ),
      ),
      GetPage(
        name: AppRoutes.sessionLog,
        page: () => SessionLogPage(
          sessionId: Get.arguments as String,
          ports: resolveAppPorts(),
        ),
      ),
    ];

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = AppRoutes.welcome});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      return _materialApp(ThemeMode.system);
    }
    return Obx(
      () => _materialApp(Get.find<ThemeController>().mode.value),
    );
  }

  Widget _materialApp(ThemeMode themeMode) {
    return GetMaterialApp(
      title: 'My Awesome Gym App',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      initialRoute: initialRoute,
      builder: (context, child) {
        final galleryPicker = Get.isRegistered<ExerciseGalleryPicker>()
            ? Get.find<ExerciseGalleryPicker>()
            : ImagePickerExerciseGalleryPicker();
        return ExerciseGalleryPickerScope(
          picker: galleryPicker,
          child: child ?? const SizedBox.shrink(),
        );
      },
      getPages: appPages(),
    );
  }
}
