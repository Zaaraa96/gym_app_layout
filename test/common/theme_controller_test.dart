import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_theme.dart';
import 'package:gym_app/common/theme_controller.dart';
import 'package:gym_app/common/widgets/app_text.dart';
import 'package:gym_app/common/widgets/theme_mode_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  group('ThemeController', () {
    test('decode maps stored values', () {
      expect(ThemeController.decode(null), ThemeMode.system);
      expect(ThemeController.decode('light'), ThemeMode.light);
      expect(ThemeController.decode('dark'), ThemeMode.dark);
      expect(ThemeController.decode('nope'), ThemeMode.system);
    });

    test('setMode persists and updates the observable', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = await ThemeController.load();
      Get.put(controller);

      await controller.setMode(ThemeMode.dark);

      expect(controller.mode.value, ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.preferenceKey), 'dark');
    });

    test('load restores a saved preference', () async {
      SharedPreferences.setMockInitialValues({
        ThemeController.preferenceKey: 'light',
      });
      final controller = await ThemeController.load();
      expect(controller.mode.value, ThemeMode.light);
    });
  });

  testWidgets('AppText fills theme colors when style omits color',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              AppText('Title', style: titleTextStyle),
              AppText('Sub', style: subtitleTextStyle),
              AppText('Data', style: dataTextStyle),
            ],
          ),
        ),
      ),
    );

    Color? colorOf(String label) {
      final text = tester.widget<Text>(find.text(label));
      return text.style?.color;
    }

    expect(colorOf('Title'), lightTheme.colorScheme.primary);
    expect(colorOf('Sub'), lightTheme.colorScheme.onSurfaceVariant);
    expect(colorOf('Data'), lightTheme.colorScheme.onSurface);
  });

  testWidgets('theme mode button switches GetMaterialApp to dark',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.put(await ThemeController.load());

    await tester.pumpWidget(
      Obx(
        () => GetMaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: Get.find<ThemeController>().mode.value,
          home: Scaffold(
            appBar: AppBar(actions: const [ThemeModeButton()]),
            body: Builder(
              builder: (context) => Text(
                Theme.of(context).brightness == Brightness.dark
                    ? 'dark-surface'
                    : 'light-surface',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('light-surface'), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-mode-dark')));
    await tester.pumpAndSettle();

    expect(find.text('dark-surface'), findsOneWidget);
    expect(Get.find<ThemeController>().mode.value, ThemeMode.dark);
  });
}
