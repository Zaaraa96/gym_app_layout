import 'package:isar/isar.dart';

import '../../domain/models/schedule.dart';
import '../../domain/new_id.dart';

part 'plan_day_skip.g.dart';

/// Lightweight skip record. Not a workout session.
@collection
class PlanDaySkip {
  Id id = Isar.autoIncrement;

  @Index()
  late String uuid;

  @Index()
  late String planId;

  late String dayId;

  /// UTC calendar day of the skip.
  @Index()
  late DateTime date;

  PlanDaySkip();

  PlanDaySkip.create({
    String? uuid,
    required this.planId,
    required this.dayId,
    required DateTime date,
  })  : uuid = uuid ?? newUuid(),
        date = utcCalendarDay(date);
}
