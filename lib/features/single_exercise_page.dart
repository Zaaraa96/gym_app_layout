
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/features/single_exercise_summery_item.dart';
import 'package:gym_app/features/single_plan/single_plan_model.dart';
import 'package:image_picker/image_picker.dart';

import '../common/widgets/app_scaffold.dart';

class SingleExercisePage extends StatelessWidget {
  const SingleExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    SingleExerciseWithRound singleExerciseWithRound = Get.arguments as SingleExerciseWithRound;
    final ThemeData theme = Theme.of(context);
    return AppScaffold(

      body:
             Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                SizedBox(height: 50,),
                 ElevatedButton(onPressed: () async {
                   // Pick singe image or video.
                   final ImagePicker picker = ImagePicker();
                   final XFile? media = await picker.pickMedia();
                 }, child: Text('open image')),
                 SingleExerciseSummeryItem(
                  backgroundColor: theme.cardColor,
                  borderColor: theme.colorScheme.primaryContainer,
                  singleExerciseWithRound: singleExerciseWithRound,
                             ),
               ],
             )
    );
  }
}
