
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/features/single_exercise_summery_item.dart';
import 'package:gym_app/features/single_plan/single_plan_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../common/widgets/app_scaffold.dart';

class SingleExercisePage extends StatefulWidget {
  const SingleExercisePage({super.key});

  @override
  State<SingleExercisePage> createState() => _SingleExercisePageState();
}

class _SingleExercisePageState extends State<SingleExercisePage> {


  var imagePath = '';

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

                   if(media == null) return;


                   var name = media.name ;

                   Directory appDocDir = await getApplicationDocumentsDirectory();
                   String appDocPath = appDocDir.path;
                   imagePath = '$appDocPath/$name';
                   print(imagePath);
                   await media.saveTo(imagePath);
                  setState(() {
                    imagePath = '$appDocPath/$name';
                  });
                 }, child: Text('open image')),

                 if(imagePath.isNotEmpty)
                 Image.file(File(imagePath), width: 100, height: 100,),

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
