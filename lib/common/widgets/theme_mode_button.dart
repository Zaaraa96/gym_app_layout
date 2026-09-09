import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme_controller.dart';

/// App-bar control to pick System, Light, or Dark appearance.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      return const SizedBox.shrink();
    }
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final mode = themeController.mode.value;
      return PopupMenuButton<ThemeMode>(
        key: const Key('theme-mode-button'),
        tooltip: 'Theme',
        icon: Icon(themeController.icon),
        initialValue: mode,
        onSelected: themeController.setMode,
        itemBuilder: (context) => [
          PopupMenuItem(
            key: const Key('theme-mode-system'),
            value: ThemeMode.system,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.brightness_auto_outlined),
              title: const Text('System'),
              trailing: mode == ThemeMode.system
                  ? const Icon(Icons.check, key: Key('theme-mode-system-check'))
                  : null,
            ),
          ),
          PopupMenuItem(
            key: const Key('theme-mode-light'),
            value: ThemeMode.light,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              trailing: mode == ThemeMode.light
                  ? const Icon(Icons.check, key: Key('theme-mode-light-check'))
                  : null,
            ),
          ),
          PopupMenuItem(
            key: const Key('theme-mode-dark'),
            value: ThemeMode.dark,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              trailing: mode == ThemeMode.dark
                  ? const Icon(Icons.check, key: Key('theme-mode-dark-check'))
                  : null,
            ),
          ),
        ],
      );
    });
  }
}
