import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme_controller.dart';

/// App-bar control to pick System, Light, or Dark appearance.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      return IconButton(
        key: const Key('theme-mode-button'),
        tooltip: 'Theme',
        onPressed: null,
        icon: const Icon(Icons.brightness_auto_outlined),
      );
    }
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      return PopupMenuButton<ThemeMode>(
        key: const Key('theme-mode-button'),
        tooltip: 'Theme',
        offset: const Offset(0, 40),
        onSelected: themeController.setMode,
        itemBuilder: (context) {
          final mode = themeController.mode.value;
          return [
            _item(
              key: const Key('theme-mode-system'),
              value: ThemeMode.system,
              icon: Icons.brightness_auto_outlined,
              label: 'System',
              selected: mode == ThemeMode.system,
              checkKey: const Key('theme-mode-system-check'),
            ),
            _item(
              key: const Key('theme-mode-light'),
              value: ThemeMode.light,
              icon: Icons.light_mode_outlined,
              label: 'Light',
              selected: mode == ThemeMode.light,
              checkKey: const Key('theme-mode-light-check'),
            ),
            _item(
              key: const Key('theme-mode-dark'),
              value: ThemeMode.dark,
              icon: Icons.dark_mode_outlined,
              label: 'Dark',
              selected: mode == ThemeMode.dark,
              checkKey: const Key('theme-mode-dark-check'),
            ),
          ];
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            themeController.icon,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    });
  }

  static PopupMenuItem<ThemeMode> _item({
    required Key key,
    required ThemeMode value,
    required IconData icon,
    required String label,
    required bool selected,
    required Key checkKey,
  }) {
    return PopupMenuItem(
      key: key,
      value: value,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (selected) Icon(Icons.check, key: checkKey),
        ],
      ),
    );
  }
}
