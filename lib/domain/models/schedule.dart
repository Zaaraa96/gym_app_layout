import '../new_id.dart';
import 'workout_plan.dart';

/// How the user follows a plan. Recurring = [ScheduleMode.week] only.
enum ScheduleMode { once, week }

/// ISO weekday: Monday = 1 … Sunday = 7 (matches [DateTime.weekday]).
typedef IsoWeekday = int;

/// Maps one plan day onto one or more weekdays when [ScheduleMode.week].
class DayWeekdayMap {
  DayWeekdayMap({
    required this.dayId,
    List<int>? weekdays,
  }) : weekdays = weekdays ?? [];

  late String dayId;

  /// Monday=1 … Sunday=7. Empty means the day is unused on the week map.
  List<int> weekdays;
}

/// Lightweight skip: no session logged. For [ScheduleMode.once], any skip of
/// [dayId] advances the pointer. For [ScheduleMode.week], only [date] (UTC day)
/// clears that day's due slot.
class PlanDaySkip {
  int id = unassignedLocalId;
  late String uuid;
  late String planId;
  late String dayId;

  /// UTC calendar day of the skip (time stripped to midnight).
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

/// Midnight UTC for [instant]'s calendar day.
DateTime utcCalendarDay(DateTime instant) {
  final u = instant.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}

const weekdayLabels = <int, String>{
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

/// Sequential Mon… mapping until days run out (migration + generic default).
List<DayWeekdayMap> sequentialWeekdayMap(List<PlanDay> days) {
  final maps = <DayWeekdayMap>[];
  for (var i = 0; i < days.length && i < 7; i++) {
    maps.add(DayWeekdayMap(dayId: days[i].dayId, weekdays: [i + 1]));
  }
  return maps;
}

/// Beginner 2-day style: Day A Mon/Wed/Thu/Sat, Day B Tue/Fri/Sun.
List<DayWeekdayMap> starterTwoDayWeekdayMap(List<PlanDay> days) {
  if (days.isEmpty) return [];
  if (days.length == 1) {
    return [
      DayWeekdayMap(dayId: days.first.dayId, weekdays: const [1, 2, 3, 4, 5, 6, 7]),
    ];
  }
  final maps = <DayWeekdayMap>[
    DayWeekdayMap(dayId: days[0].dayId, weekdays: const [1, 3, 4, 6]),
    DayWeekdayMap(dayId: days[1].dayId, weekdays: const [2, 5, 7]),
  ];
  // Extra imported days share remaining slots already covered; leave unmapped.
  return maps;
}

/// Beginner full-body: map days across the week so every weekday has a workout.
List<DayWeekdayMap> starterFullBodyWeekdayMap(List<PlanDay> days) {
  if (days.isEmpty) return [];
  const preferred = [1, 3, 5, 2, 4, 6, 7]; // Mon Wed Fri Tue Thu Sat Sun
  final maps = <DayWeekdayMap>[];
  for (var i = 0; i < days.length && i < preferred.length; i++) {
    maps.add(DayWeekdayMap(dayId: days[i].dayId, weekdays: [preferred[i]]));
  }
  return maps;
}

/// True when every startable workout day has ≥1 weekday in [plan.weekdayMap].
bool weekdayMapIsComplete(WorkoutPlan plan) {
  if (plan.scheduleMode != ScheduleMode.week) return true;
  for (final day in plan.days) {
    if (day.blocks.isEmpty) continue;
    final entry = plan.weekdayMap.where((m) => m.dayId == day.dayId);
    if (entry.isEmpty || entry.first.weekdays.isEmpty) return false;
  }
  return true;
}

/// Fills missing schedule defaults without overwriting an explicit map.
void ensurePlanScheduleDefaults(WorkoutPlan plan) {
  if (plan.weekdayMap.isEmpty &&
      plan.scheduleMode == ScheduleMode.week &&
      plan.days.isNotEmpty) {
    plan.weekdayMap = sequentialWeekdayMap(plan.days);
  }
}

/// Weekdays already claimed by other days (for UI conflict hints).
Set<int> claimedWeekdays(
  WorkoutPlan plan, {
  String? exceptDayId,
}) {
  final claimed = <int>{};
  for (final entry in plan.weekdayMap) {
    if (exceptDayId != null && entry.dayId == exceptDayId) continue;
    claimed.addAll(entry.weekdays);
  }
  return claimed;
}

List<int> weekdaysForDay(WorkoutPlan plan, String dayId) {
  for (final entry in plan.weekdayMap) {
    if (entry.dayId == dayId) return List<int>.from(entry.weekdays);
  }
  return const [];
}

void setWeekdaysForDay(WorkoutPlan plan, String dayId, List<int> weekdays) {
  final next = weekdays.toSet().toList()..sort();
  final index = plan.weekdayMap.indexWhere((m) => m.dayId == dayId);
  if (index < 0) {
    plan.weekdayMap = [
      ...plan.weekdayMap,
      DayWeekdayMap(dayId: dayId, weekdays: next),
    ];
  } else {
    plan.weekdayMap = [
      for (var i = 0; i < plan.weekdayMap.length; i++)
        if (i == index)
          DayWeekdayMap(dayId: dayId, weekdays: next)
        else
          plan.weekdayMap[i],
    ];
  }
}
