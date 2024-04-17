import 'package:flutter/material.dart';

import 'common/app_theme.dart';
import 'features/single_day_plan_page.dart';
import 'features/welcome_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      home: const SingleDayPlan(),
    );
  }
}
