import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';

export 'app/app_bootstrap.dart';
export 'app/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // First frame must not wait on Isar. The Linux view and Android night
  // launch theme are black until Flutter paints.
  runApp(const AppBootstrap());
}
