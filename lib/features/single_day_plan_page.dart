import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../common/widgets/app_scaffold.dart';
import '../common/widgets/app_text.dart';

class SingleExerciseModel{

}


class SingleDayPlan extends StatelessWidget {
  const SingleDayPlan({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppScaffold(
      appbar: AppBar(
        title: const Text('Day 1'),
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
            );
          },
          //     separatorBuilder: (context, int item){
          //   return const Divider(height: 6, thickness: 1,);
          // },
          itemCount: 5),
    );
  }
}

class SingleExerciseSummeryItem extends StatelessWidget {
  const SingleExerciseSummeryItem({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
  });

  final roundNum = 3;
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
              'assets/image/upper-body.svg',
              width: 40,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExerciseWithRepetition(),
                ExerciseWithRepetition(),
              ],
            ),

            ///round
            RoundNumberWidget(roundNum: roundNum),
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
    super.key,
  });

  final repetition = 12;
  final title = 'Dead lift';
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          title,
          style: dataTextStyle,
        ),
        SizedBox(
          width: 6,
        ),
        AppText(
          'x$repetition',
          style: dataTextStyle.copyWith(fontWeight: FontWeight.w700),
        )
      ],
    );
  }
}
