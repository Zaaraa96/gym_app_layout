import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/workout_plan.dart';
import 'models/workout_session.dart';

/// Opens Isar once for the process and exposes the instance as a GetX service.
class IsarService extends GetxService {
  IsarService(this.isar);

  final Isar isar;

  static IsarService get to => Get.find<IsarService>();

  /// Production collections. Tests open the same set in a temp directory.
  static final schemas = [
    WorkoutPlanSchema,
    WorkoutSessionSchema,
  ];

  static Future<IsarService> init({
    String? directory,
    String name = Isar.defaultName,
  }) async {
    final dir = directory ?? (await getApplicationDocumentsDirectory()).path;
    final isar = Isar.getInstance(name) ?? await Isar.open(
      schemas,
      directory: dir,
      name: name,
    );
    return IsarService(isar);
  }

  Future<bool> close({bool deleteFromDisk = false}) =>
      isar.close(deleteFromDisk: deleteFromDisk);
}
