import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app_bootstrap.dart';
import 'common/theme_controller.dart';

export 'app/app_bootstrap.dart';
export 'app/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load appearance before the first frame so launch is not a theme flash.
  Get.put(await ThemeController.load());
  // First frame must not wait on Isar. The Linux view and Android night
  // launch theme are black until Flutter paints.
  runApp(const AppBootstrap());
}
