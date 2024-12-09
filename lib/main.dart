import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import 'common/app_theme.dart';
import 'features/add_plan_page.dart';
import 'features/single_day_plan_page.dart';
import 'features/single_plan/single_plan_model.dart';
import 'features/single_plan/single_plan_page.dart';
import 'features/welcome_page.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();

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
    return GetMaterialApp(
      title: 'My Awesome Gym App',
      theme: appTheme,
      initialRoute: '/new-plan',
      getPages: [

        GetPage(name: '/new-plan', page: () => const AddNewPlanPage()),
        GetPage(name: '/', page: () => const WelcomePage()),
        GetPage(name: '/plan', page: () => SinglePlanPage(plan: SinglePlanModel(title: 'your amazing plan',
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

            ]),)),
        GetPage(name: '/day', page: ()=> SingleDayPlan()),
      ],



    );
  }
}

//todo: add getX for storage