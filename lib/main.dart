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
      home:  SingleDayPlan(singleDayPlanModel: SingleDayPlanModel(title: 'Day 1', exercises: [
        SingleExerciseWithRound(
          exerciseWithRepetitionModels: [
            ExerciseWithRepetitionModel(repetition: 12, title: 'Dead lift'),
            ExerciseWithRepetitionModel(repetition: 12, title: 'Dead lift')
          ], roundNum: 3, svgPath: 'assets/image/upper-body.svg'
      ),
        SingleExerciseWithRound(
          exerciseWithRepetitionModels: [
            ExerciseWithRepetitionModel(repetition: 15, title: 'Dead lift'),
            ExerciseWithRepetitionModel(repetition: 15, title: 'Dead lift')
          ], roundNum: 4, svgPath: 'assets/image/upper-body.svg'
      ),
      ]

      ), ),
    );
  }
}
