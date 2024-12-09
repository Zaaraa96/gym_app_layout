import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:gym_app/features/single_exercise_summery_item.dart';
import 'package:gym_app/features/single_plan/single_plan_model.dart';

import '../common/widgets/app_scaffold.dart';
import '../common/widgets/app_text.dart';



class SingleDayPlan extends StatelessWidget {
  const SingleDayPlan({super.key});


  @override
  Widget build(BuildContext context) {
    SingleDayPlanModel singleDayPlanModel = Get.arguments as SingleDayPlanModel;
    final ThemeData theme = Theme.of(context);
    return AppScaffold(
      appbar: AppBar(
        title:  Text(singleDayPlanModel.title),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemBuilder: (context, int item) {
            return GestureDetector(
              onTap: (){
                Get.toNamed("/exercise", arguments: singleDayPlanModel.exercises![item]);
              },
              child: SingleExerciseSummeryItem(
                backgroundColor: item % 2 == 0
                    ? theme.colorScheme.surfaceVariant
                    : theme.cardColor,
                borderColor: theme.colorScheme.primaryContainer,
                singleExerciseWithRound: singleDayPlanModel.exercises![item],
              ),
            );
          },
          itemCount: singleDayPlanModel.exercises?.length ??0),
    );
  }
}
