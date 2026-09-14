import 'dart:convert';
import 'dart:io';

import 'models/models.dart';
import 'once_plan_cycle.dart';
import 'plan_repository.dart';
import 'session_repository.dart';
import 'skip_repository.dart';

/// Kind of item the home Today list can show.
enum TodayItemKind { workout, rest }

/// One due item for Today (workout start/skip, or Week Rest).
class TodayItem {
  const TodayItem({
    required this.plan,
    required this.kind,
    required this.headline,
    required this.prompt,
    this.day,
    this.alreadyTrainedToday = false,
  });

  final WorkoutPlan plan;
  final PlanDay? day;
  final TodayItemKind kind;
  final bool alreadyTrainedToday;
  final String headline;
  final String prompt;

  bool get isRest => kind == TodayItemKind.rest;
  bool get isWorkout => kind == TodayItemKind.workout;
}

/// Back-compat alias used by older call sites / tests.
typedef TodaySuggestion = TodayItem;

/// True when Start would copy at least one block.
bool dayCanStart(WorkoutPlan plan, PlanDay day) =>
    plan.status == PlanStatus.active && day.blocks.isNotEmpty;

String firstExerciseTitle(PlanDay day, [WorkoutPlan? plan]) {
  for (final block in day.blocks) {
    if (block.exercises.isNotEmpty) return block.exercises.first.title;
  }
  return 'your first exercise';
}

bool sameUtcDay(DateTime a, DateTime b) {
  final left = a.toUtc();
  final right = b.toUtc();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _dayCompleted({
  required WorkoutPlan plan,
  required String dayId,
  required List<WorkoutSession> completedNewestFirst,
}) {
  for (final session in completedNewestFirst) {
    if (session.planId == plan.uuid &&
        session.planDayId == dayId &&
        sessionCountsForOnceCycle(plan, session)) {
      return true;
    }
  }
  return false;
}

bool _daySkippedOnce({
  required WorkoutPlan plan,
  required String dayId,
  required List<PlanDaySkip> skips,
}) {
  for (final skip in skips) {
    if (skip.planId == plan.uuid &&
        skip.dayId == dayId &&
        skipCountsForOnceCycle(plan, skip)) {
      return true;
    }
  }
  return false;
}

bool _daySkippedOnDate({
  required String planId,
  required String dayId,
  required DateTime day,
  required List<PlanDaySkip> skips,
}) {
  final target = utcCalendarDay(day);
  for (final skip in skips) {
    if (skip.planId == planId &&
        skip.dayId == dayId &&
        sameUtcDay(skip.date, target)) {
      return true;
    }
  }
  return false;
}

bool _trainedPlanDayToday({
  required String planId,
  required String dayId,
  required List<WorkoutSession> completedNewestFirst,
  required DateTime now,
}) {
  for (final session in completedNewestFirst) {
    if (session.planId == planId &&
        session.planDayId == dayId &&
        sameUtcDay(session.startedAt, now)) {
      return true;
    }
  }
  return false;
}

/// Next incomplete/unskipped workout for a Run-once plan, or null when finished.
TodayItem? dueItemForOncePlan({
  required WorkoutPlan plan,
  required List<WorkoutSession> completedNewestFirst,
  required List<PlanDaySkip> skips,
  required DateTime now,
}) {
  ensurePlanScheduleDefaults(plan);
  if (!plan.feedsToday) return null;

  final startable = [
    for (final day in plan.days)
      if (dayCanStart(plan, day)) day,
  ];
  if (startable.isEmpty) return null;

  PlanDay? next;
  for (final day in startable) {
    final done = _dayCompleted(
      plan: plan,
      dayId: day.dayId,
      completedNewestFirst: completedNewestFirst,
    );
    final skipped = _daySkippedOnce(
      plan: plan,
      dayId: day.dayId,
      skips: skips,
    );
    if (!done && !skipped) {
      next = day;
      break;
    }
  }
  if (next == null) return null;

  final trainedToday = _trainedPlanDayToday(
        planId: plan.uuid,
        dayId: next.dayId,
        completedNewestFirst: completedNewestFirst,
        now: now,
      ) ||
      // After skip earlier today on a previous day, still "next up" feel if any
      // completion/skip happened today for this plan.
      completedNewestFirst.any(
        (s) => s.planId == plan.uuid && sameUtcDay(s.startedAt, now),
      ) ||
      skips.any(
        (s) => s.planId == plan.uuid && sameUtcDay(s.date, now),
      );

  final first = firstExerciseTitle(next);
  if (trainedToday) {
    return TodayItem(
      plan: plan,
      day: next,
      kind: TodayItemKind.workout,
      alreadyTrainedToday: true,
      headline: 'Next up: ${next.title}',
      prompt:
          'You already trained today. When you are ready, start with $first and log what you did.',
    );
  }
  return TodayItem(
    plan: plan,
    day: next,
    kind: TodayItemKind.workout,
    alreadyTrainedToday: false,
    headline: 'Today: ${next.title}',
    prompt: 'Start with $first, then log what you did.',
  );
}

/// Week schedule: mapped workout for [now]'s weekday, or Rest when none.
TodayItem? dueItemForWeekPlan({
  required WorkoutPlan plan,
  required List<WorkoutSession> completedNewestFirst,
  required List<PlanDaySkip> skips,
  required DateTime now,
}) {
  ensurePlanScheduleDefaults(plan);
  if (!plan.feedsToday) return null;

  final weekday = now.toLocal().weekday; // Mon=1…Sun=7
  PlanDay? mapped;
  for (final entry in plan.weekdayMap) {
    if (!entry.weekdays.contains(weekday)) continue;
    for (final day in plan.days) {
      if (day.dayId == entry.dayId && dayCanStart(plan, day)) {
        mapped = day;
        break;
      }
    }
    if (mapped != null) break;
  }

  if (mapped == null) {
    return TodayItem(
      plan: plan,
      day: null,
      kind: TodayItemKind.rest,
      headline: '${plan.displayTitle}: Rest',
      prompt: 'No workout mapped for today. Recover, or train anyway from the plan.',
    );
  }

  if (_daySkippedOnDate(
    planId: plan.uuid,
    dayId: mapped.dayId,
    day: now,
    skips: skips,
  )) {
    return null;
  }

  final trainedToday = _trainedPlanDayToday(
    planId: plan.uuid,
    dayId: mapped.dayId,
    completedNewestFirst: completedNewestFirst,
    now: now,
  );
  final first = firstExerciseTitle(mapped);
  if (trainedToday) {
    // Already logged today's mapped day — not due again.
    return null;
  }
  return TodayItem(
    plan: plan,
    day: mapped,
    kind: TodayItemKind.workout,
    alreadyTrainedToday: false,
    headline: 'Today: ${mapped.title}',
    prompt: 'Start with $first, then log what you did.',
  );
}

TodayItem? dueItemForPlan({
  required WorkoutPlan plan,
  required List<WorkoutSession> completedNewestFirst,
  required List<PlanDaySkip> skips,
  required DateTime now,
}) {
  if (!plan.feedsToday) return null;
  switch (plan.scheduleMode) {
    case ScheduleMode.once:
      return dueItemForOncePlan(
        plan: plan,
        completedNewestFirst: completedNewestFirst,
        skips: skips,
        now: now,
      );
    case ScheduleMode.week:
      return dueItemForWeekPlan(
        plan: plan,
        completedNewestFirst: completedNewestFirst,
        skips: skips,
        now: now,
      );
  }
}

/// Every due item from on-schedule active plans (workouts first, then Rest).
List<TodayItem> suggestTodayItems({
  required List<WorkoutPlan> plans,
  List<WorkoutSession> completedNewestFirst = const [],
  List<PlanDaySkip> skips = const [],
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final workouts = <TodayItem>[];
  final rests = <TodayItem>[];
  for (final plan in plans) {
    if (!plan.feedsToday) continue;
    final item = dueItemForPlan(
      plan: plan,
      completedNewestFirst: completedNewestFirst,
      skips: skips,
      now: clock,
    );
    if (item == null) continue;
    if (item.isRest) {
      rests.add(item);
    } else {
      workouts.add(item);
    }
  }
  return [...workouts, ...rests];
}

/// First workout due item, or null. Prefer [suggestTodayItems] for the list UI.
TodayItem? suggestToday({
  required List<WorkoutPlan> plans,
  List<WorkoutSession> completedNewestFirst = const [],
  List<PlanDaySkip> skips = const [],
  DateTime? now,
}) {
  for (final item in suggestTodayItems(
    plans: plans,
    completedNewestFirst: completedNewestFirst,
    skips: skips,
    now: now,
  )) {
    if (item.isWorkout) return item;
  }
  return null;
}

/// Plans, live session, and today's due list.
class HomeOverview {
  const HomeOverview({
    required this.plans,
    this.live,
    this.todayItems = const [],
  });

  final List<WorkoutPlan> plans;
  final WorkoutSession? live;
  final List<TodayItem> todayItems;

  /// First workout due item (tests / older UI).
  TodayItem? get today {
    for (final item in todayItems) {
      if (item.isWorkout) return item;
    }
    return null;
  }

  bool get hasOnSchedulePlans => plans.any((p) => p.feedsToday);
}

/// One read for the home screen.
Future<HomeOverview> loadHomeOverview({
  required PlanRepository plans,
  required SessionRepository sessions,
  SkipRepository? skips,
  DateTime? now,
}) async {
  final items = await plans.all();
  final live = await sessions.inProgress();
  final completed = await sessions.completedNewestFirst();
  final skipRows = skips == null ? <PlanDaySkip>[] : await skips.all();
  for (final plan in items) {
    ensurePlanScheduleDefaults(plan);
    if (plan.scheduleMode == ScheduleMode.once &&
        plan.onSchedule &&
        oncePlanIsFinished(
          plan: plan,
          completedNewestFirst: completed,
          skips: skipRows,
        )) {
      // #region agent log
      try {
        File('/opt/cursor/logs/debug.log').writeAsStringSync(
          '${jsonEncode({
            'hypothesisId': 'E',
            'location': 'today_suggestion.dart:loadHomeOverview',
            'message': 'parking via loadHomeOverview all()',
            'data': {
              'planId': plan.uuid,
              'skipCount': skipRows.length,
              'skipDayIds': [for (final s in skipRows) s.dayId],
              'skipPlanIds': [for (final s in skipRows) s.planId],
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          })}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      plan.onSchedule = false;
      await plans.save(plan);
    }
  }
  return HomeOverview(
    plans: items,
    live: live,
    todayItems: suggestTodayItems(
      plans: items,
      completedNewestFirst: completed,
      skips: skipRows,
      now: now,
    ),
  );
}
