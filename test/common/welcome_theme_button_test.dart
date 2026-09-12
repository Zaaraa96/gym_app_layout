import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/theme_controller.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_repository.dart';
import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/features/welcome/welcome_page.dart';
import 'package:gym_app/common/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  testWidgets('welcome shows theme button when controller registered', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.put(await ThemeController.load());
    Get.put<PlanRepository>(MemoryPlanRepository());
    Get.put<SessionRepository>(MemorySessionRepository());
    final ports = AppPorts(
      plans: Get.find<PlanRepository>(),
      sessions: Get.find<SessionRepository>(),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        home: WelcomePage(ports: ports),
      ),
    );
    expect(find.byKey(const Key('theme-mode-button')), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
