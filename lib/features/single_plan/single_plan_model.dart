
import 'package:isar/isar.dart';

part 'single_plan_model.g.dart';

@collection
class SinglePlanModel{

  Id id = Isar.autoIncrement;

  final String title;

  final List<SingleDayPlanModel> dayPlans;

  SinglePlanModel({required this.title, required this.dayPlans});
}

@embedded
class SingleDayPlanModel{
  final String title;
  final String summary;
   List<SingleExerciseWithRound>? exercises= [];

  SingleDayPlanModel({this.title='',this.exercises,this.summary=''});
}

@embedded
class SingleExerciseWithRound{
    List<ExerciseWithRepetitionModel>? exerciseWithRepetitionModels=[];
  final int roundNum;
  final String svgPath;

  SingleExerciseWithRound({this.exerciseWithRepetitionModels,this.roundNum= 1,this.svgPath = ''});
}

@embedded
class ExerciseWithRepetitionModel{
  final int repetition;
  final String title;

  ExerciseWithRepetitionModel({this.repetition = 1,this.title = ''});
}
