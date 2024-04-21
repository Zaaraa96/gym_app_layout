import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../common/widgets/app_scaffold.dart';
import '../common/widgets/app_text.dart';


class SingleDayPlanModel{
  final String title;
  final String summary;
  final List<SingleExerciseWithRound> exercises;

  SingleDayPlanModel({required this.title, required this.exercises, required this.summary});
}

class SingleExerciseWithRound{
  final  List<ExerciseWithRepetitionModel> exerciseWithRepetitionModels;
  final int roundNum;
  final String svgPath;

  SingleExerciseWithRound({required this.exerciseWithRepetitionModels, required this.roundNum, required this.svgPath});
}

class ExerciseWithRepetitionModel{
  final int repetition;
  final String title;

  ExerciseWithRepetitionModel({required this.repetition, required this.title});
}


class SingleDayPlan extends StatelessWidget {
  const SingleDayPlan({super.key, required this.singleDayPlanModel});
  final SingleDayPlanModel singleDayPlanModel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppScaffold(
      appbar: AppBar(
        title:  Text(singleDayPlanModel.title),
      ),
      body: ListView.builder(
        padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemBuilder: (context, int item) {
            return SingleExerciseSummeryItem(
              backgroundColor: item % 2 == 0
                  ? theme.colorScheme.surfaceVariant
                  : theme.cardColor,
              borderColor: theme.colorScheme.primaryContainer,
              singleExerciseWithRound: singleDayPlanModel.exercises[item],
            );
          },
          itemCount: singleDayPlanModel.exercises.length),
    );
  }
}

class SingleExerciseSummeryItem extends StatelessWidget {
  const SingleExerciseSummeryItem({
    super.key,
    required this.backgroundColor,
    required this.borderColor, required this.singleExerciseWithRound,
  });

  final SingleExerciseWithRound singleExerciseWithRound;

  final Color backgroundColor;
  final Color borderColor;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ///svg that determines
            SvgPicture.asset(
              singleExerciseWithRound.svgPath,
              width: 40,
            ),
             Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var exerciseWithRepetitionModel in singleExerciseWithRound.exerciseWithRepetitionModels)
                   ExerciseWithRepetition(exerciseWithRepetitionModel: exerciseWithRepetitionModel,),
              ],
            ),

            ///round
            RoundNumberWidget(roundNum: singleExerciseWithRound.roundNum),
          ],
        ),
      ),
    );
  }
}

class RoundNumberWidget extends StatelessWidget {
  const RoundNumberWidget({
    super.key,
    required this.roundNum,
  });

  final int roundNum;
  final double size = 55;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          shape: BoxShape.circle,
          color: theme.colorScheme.primaryContainer),
      child: Center(
          child: AppText(
        '$roundNum',
        style: titleTextStyle.copyWith(fontWeight: FontWeight.w700),
      )),
    );
  }
}

class ExerciseWithRepetition extends StatelessWidget {
  const ExerciseWithRepetition({
    super.key, required this.exerciseWithRepetitionModel,
  });
  //
  // final repetition = 12;
  // final title = 'Dead lift';
  final ExerciseWithRepetitionModel exerciseWithRepetitionModel;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          exerciseWithRepetitionModel.title,
          style: dataTextStyle,
        ),
        const SizedBox(
          width: 6,
        ),
        AppText(
          'x${exerciseWithRepetitionModel.repetition}',
          style: dataTextStyle.copyWith(fontWeight: FontWeight.w700),
        )
      ],
    );
  }
}
