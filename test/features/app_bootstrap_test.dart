import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/domain/plan_repository.dart';
import 'package:gym_app/domain/session_repository.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);

  testWidgets('the first frame is a themed loader, not an empty route',
      (tester) async {
    final boot = Completer<String>();
    await tester.pumpWidget(AppBootstrap(boot: () => boot.future));

    expect(find.byKey(const Key('app-boot')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(GetMaterialApp), findsNothing);
  });

  testWidgets('a failed boot shows retry instead of staying blank',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      AppBootstrap(
        boot: () async {
          calls += 1;
          if (calls == 1) {
            throw StateError('isar locked');
          }
          Get.put<PlanRepository>(MemoryPlanRepository());
          Get.put<SessionRepository>(MemorySessionRepository());
          return AppRoutes.welcome;
        },
      ),
    );
    // Theme prefs load, then boot throws — both need a frame.
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Could not open the app'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.text('Welcome To the Amazing Gym app'), findsOneWidget);
  });

  testWidgets('saved dark preference themes the boot loader', (tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
    });
    final boot = Completer<String>();
    await tester.pumpWidget(AppBootstrap(boot: () => boot.future));
    await tester.pump();
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.byKey(const Key('app-boot')), findsOneWidget);
  });
}
