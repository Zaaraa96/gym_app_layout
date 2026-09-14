import 'dart:convert';
import 'dart:io';

import 'models/models.dart';
import 'once_plan_cycle.dart';
import 'session_repository.dart';
import 'skip_repository.dart';
import 'today_suggestion.dart';

/// Per-plan progress shown on Plan preview.
class PlanProgress {
  const PlanProgress({
    required this.mode,
    required this.doneCount,
    required this.skippedCount,
    required this.leftCount,
    required this.totalWorkoutDays,
    required this.dayStates,
    required this.dayTitles,
    required this.weekStrip,
    required this.trainedThisWeek,
    required this.skippedThisWeek,
    required this.leftThisWeek,
    this.lastTrainedAt,
    this.weightTrend = const [],
    this.weeklySessionCounts = const [],
    this.isFinishedOnce = false,
  });

  final ScheduleMode mode;
  final int doneCount;
  final int skippedCount;
  final int leftCount;
  final int totalWorkoutDays;
  final Map<String, PlanDayProgressState> dayStates;
  final Map<String, String> dayTitles;

  /// Mon…Sun strip for week mode (trained / skipped / rest / upcoming).
  final List<WeekStripCell> weekStrip;
  final int trainedThisWeek;
  final int skippedThisWeek;
  final int leftThisWeek;
  final DateTime? lastTrainedAt;

  /// Plan-scoped weight points (session date → max weight).
  final List<PlanChartPoint> weightTrend;

  /// Last several local weeks: week-start → completed session count.
  final List<PlanChartPoint> weeklySessionCounts;

  /// Run-once cycle has no days left.
  final bool isFinishedOnce;

  String get onceHeadline {
    if (isFinishedOnce) {
      final skipBit =
          skippedCount == 0 ? '' : ' · $skippedCount skipped';
      return 'Completed · $doneCount of $totalWorkoutDays done$skipBit';
    }
    final skipBit =
        skippedCount == 0 ? '' : ' · $skippedCount skipped';
    return '$doneCount of $totalWorkoutDays done$skipBit';
  }

  String get weekHeadline =>
      'This week: $trainedThisWeek trained · $skippedThisWeek skipped · $leftThisWeek left';
}

enum PlanDayProgressState { done, skipped, left }

enum WeekStripMark { rest, trained, skipped, due, upcoming }

class WeekStripCell {
  const WeekStripCell({
    required this.weekday,
    required this.mark,
    this.dayTitle,
  });

  final int weekday;
  final WeekStripMark mark;
  final String? dayTitle;
}

class PlanChartPoint {
  const PlanChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

Future<PlanProgress> loadPlanProgress({
  required WorkoutPlan plan,
  required SessionRepository sessions,
  required SkipRepository skips,
  DateTime? now,
}) async {
  ensurePlanScheduleDefaults(plan);
  final clock = now ?? DateTime.now();
  final completedNewest = await sessions.completedNewestFirst(planId: plan.uuid);
  final completed = completedNewest.reversed.toList();
  final skipRows = await skips.forPlan(plan.uuid);

  final workoutDays = [
    for (final day in plan.days)
      if (day.blocks.isNotEmpty) day,
  ];

  final dayStates = <String, PlanDayProgressState>{};
  final dayTitles = <String, String>{
    for (final day in workoutDays) day.dayId: day.title,
  };
  var done = 0;
  var skipped = 0;
  var left = 0;

  if (plan.scheduleMode == ScheduleMode.once) {
    for (final day in workoutDays) {
      final isDone = completed.any(
        (s) =>
            s.planDayId == day.dayId && sessionCountsForOnceCycle(plan, s),
      );
      final isSkipped = skipRows.any(
        (s) => s.dayId == day.dayId && skipCountsForOnceCycle(plan, s),
      );
      // #region agent log
      try {
        File('/opt/cursor/logs/debug.log').writeAsStringSync(
          '${jsonEncode({
            'hypothesisId': 'C',
            'location': 'plan_progress.dart:onceDay',
            'message': 'once day progress classify',
            'data': {
              'dayId': day.dayId,
              'isDone': isDone,
              'isSkipped': isSkipped,
              'skipRowDayIds': [for (final s in skipRows) s.dayId],
              'skipRowPlanIds': [for (final s in skipRows) s.planId],
              'onceCycleStartedAt': plan.onceCycleStartedAt?.toIso8601String(),
              'skipCounts': [
                for (final s in skipRows)
                  if (s.dayId == day.dayId) skipCountsForOnceCycle(plan, s),
              ],
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          })}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      if (isDone) {
        dayStates[day.dayId] = PlanDayProgressState.done;
        done += 1;
      } else if (isSkipped) {
        dayStates[day.dayId] = PlanDayProgressState.skipped;
        skipped += 1;
      } else {
        dayStates[day.dayId] = PlanDayProgressState.left;
        left += 1;
      }
    }
  } else {
    // Week: lifetime day list still useful; week strip carries adherence.
    for (final day in workoutDays) {
      final isDone = completed.any((s) => s.planDayId == day.dayId);
      dayStates[day.dayId] = isDone
          ? PlanDayProgressState.done
          : PlanDayProgressState.left;
      if (isDone) {
        done += 1;
      } else {
        left += 1;
      }
    }
  }

  DateTime? lastTrained;
  if (completed.isNotEmpty) {
    lastTrained = completed.last.startedAt;
  }

  final localNow = clock.toLocal();
  final weekStart = DateTime(localNow.year, localNow.month, localNow.day)
      .subtract(Duration(days: localNow.weekday - 1));

  var trainedThisWeek = 0;
  var skippedThisWeek = 0;
  var leftThisWeek = 0;
  final strip = <WeekStripCell>[];

  for (var weekday = 1; weekday <= 7; weekday++) {
    final date = weekStart.add(Duration(days: weekday - 1));
    PlanDay? mapped;
    for (final entry in plan.weekdayMap) {
      if (!entry.weekdays.contains(weekday)) continue;
      for (final day in plan.days) {
        if (day.dayId == entry.dayId) {
          mapped = day;
          break;
        }
      }
      if (mapped != null) break;
    }

    if (mapped == null || mapped.blocks.isEmpty) {
      strip.add(WeekStripCell(weekday: weekday, mark: WeekStripMark.rest));
      continue;
    }

    final trained = completed.any(
      (s) =>
          s.planDayId == mapped!.dayId &&
          sameLocalDay(s.startedAt.toLocal(), date),
    );
    // Compare skip records using the strip cell's local Y-M-D as the calendar
    // day label (same convention as utcCalendarDay for "which calendar day").
    final cellDay = DateTime.utc(date.year, date.month, date.day);
    final skippedDay = skipRows.any(
      (s) => s.dayId == mapped!.dayId && sameUtcDay(s.date, cellDay),
    );

    if (trained) {
      trainedThisWeek += 1;
      strip.add(WeekStripCell(
        weekday: weekday,
        mark: WeekStripMark.trained,
        dayTitle: mapped.title,
      ));
    } else if (skippedDay) {
      skippedThisWeek += 1;
      strip.add(WeekStripCell(
        weekday: weekday,
        mark: WeekStripMark.skipped,
        dayTitle: mapped.title,
      ));
    } else if (date.isAfter(DateTime(localNow.year, localNow.month, localNow.day))) {
      leftThisWeek += 1;
      strip.add(WeekStripCell(
        weekday: weekday,
        mark: WeekStripMark.upcoming,
        dayTitle: mapped.title,
      ));
    } else if (sameLocalDay(date, localNow)) {
      leftThisWeek += 1;
      strip.add(WeekStripCell(
        weekday: weekday,
        mark: WeekStripMark.due,
        dayTitle: mapped.title,
      ));
    } else {
      leftThisWeek += 1;
      strip.add(WeekStripCell(
        weekday: weekday,
        mark: WeekStripMark.upcoming,
        dayTitle: mapped.title,
      ));
    }
  }

  // Weight trend across completed sessions for this plan.
  final weightTrend = <PlanChartPoint>[];
  for (final session in completed) {
    double? maxW;
    for (final log in session.exerciseLogs) {
      for (final set in log.sets) {
        final w = set.weightKg;
        if (w == null) continue;
        maxW = maxW == null ? w : (w > maxW ? w : maxW);
      }
    }
    if (maxW == null) continue;
    final d = session.startedAt.toLocal();
    weightTrend.add(PlanChartPoint(
      label: '${d.month}/${d.day}',
      value: maxW,
    ));
  }

  // Weekly session counts for the last 6 local weeks.
  final weekly = <PlanChartPoint>[];
  for (var i = 5; i >= 0; i--) {
    final start = weekStart.subtract(Duration(days: 7 * i));
    final end = start.add(const Duration(days: 7));
    var count = 0;
    for (final s in completed) {
      final local = s.startedAt.toLocal();
      if (!local.isBefore(start) && local.isBefore(end)) count += 1;
    }
    weekly.add(PlanChartPoint(
      label: '${start.month}/${start.day}',
      value: count.toDouble(),
    ));
  }

  return PlanProgress(
    mode: plan.scheduleMode,
    doneCount: done,
    skippedCount: skipped,
    leftCount: left,
    totalWorkoutDays: workoutDays.length,
    dayStates: dayStates,
    dayTitles: dayTitles,
    weekStrip: strip,
    trainedThisWeek: trainedThisWeek,
    skippedThisWeek: skippedThisWeek,
    leftThisWeek: leftThisWeek,
    lastTrainedAt: lastTrained,
    weightTrend: weightTrend,
    weeklySessionCounts: weekly,
    isFinishedOnce: plan.scheduleMode == ScheduleMode.once && left == 0 && workoutDays.isNotEmpty,
  );
}

bool sameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
