import 'package:flutter/material.dart';

import 'common/app_theme.dart';
import 'features/single_day_plan_page.dart';
import 'features/single_plan_page.dart';
import 'features/welcome_page.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  final SingleExerciseWithRound exerciseWithRound = SingleExerciseWithRound(
      exerciseWithRepetitionModels: [
        ExerciseWithRepetitionModel(repetition: 12, title: 'Dead lift'),
        ExerciseWithRepetitionModel(repetition: 12, title: 'Dead lift')
      ], roundNum: 3, svgPath: 'assets/image/upper-body.svg'
  );
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      home:
      SinglePlanPage(plan: SinglePlanModel(title: 'your amazing plan',
          dayPlans: [
          SingleDayPlanModel(title: 'Day 1',
              summary: "upper body, core with some ٖcorrective actions",
              exercises: [
                exerciseWithRound,
                exerciseWithRound,
            ],
            ),
            SingleDayPlanModel(title: 'Day 2',
              summary: "upper body, core with some ٖcorrective actions",
              exercises: [
                exerciseWithRound,
                exerciseWithRound,
              ],
            ),
          SingleDayPlanModel(title: 'Day 3',
              summary: "upper body, core with some ٖcorrective actions",
              exercises: [
                exerciseWithRound,
                exerciseWithRound,
            ],
            ),
          SingleDayPlanModel(title: 'Day 4',
              summary: "upper body, core with some ٖcorrective actions",
              exercises: [
                exerciseWithRound,
                exerciseWithRound,
            ],
            ),

      ]),)

    );
  }
}

//todo: next is adding getX for routing