import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../features/single_plan/single_plan_model.dart';
import 'models/workout_plan.dart';
import 'models/workout_session.dart';

/// Opens Isar once for the process and exposes the instance as a GetX service.
class IsarService extends GetxService {
  IsarService(this.isar);

  final Isar isar;

  static IsarService get to => Get.find<IsarService>();

  static Future<IsarService> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        WorkoutPlanSchema,
        WorkoutSessionSchema,
        // Kept until later slices drop the demo create-plan path.
        SinglePlanModelSchema,
      ],
      directory: dir.path,
    );
    return IsarService(isar);
  }
}
