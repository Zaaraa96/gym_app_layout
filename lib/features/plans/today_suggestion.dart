import '../../data/models/models.dart';
import '../../data/plan_repository.dart';
import '../../data/session_repository.dart';

/// A startable day the home screen can recommend.
class TodaySuggestion {
  const TodaySuggestion({
    required this.plan,
    required this.day,
    required this.alreadyTrainedToday,
    required this.headline,
    required this.prompt,
  });

  final WorkoutPlan plan;
  final PlanDay day;
  final bool alreadyTrainedToday;
  final String headline;
  final String prompt;
}

/// True when Start would copy at least one block, or commons can fill a session.
bool dayCanStart(WorkoutPlan plan, PlanDay day) =>
    day.blocks.isNotEmpty || plan.commonSections.isNotEmpty;

String firstExerciseTitle(PlanDay day, WorkoutPlan plan) {
  for (final block in day.blocks) {
    if (block.exercises.isNotEmpty) return block.exercises.first.title;
  }
  for (final section in plan.commonSections) {
    for (final block in section.blocks) {
      if (block.exercises.isNotEmpty) return block.exercises.first.title;
    }
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

/// Next day on the newest startable plan, rotating after the last completed day.
///
/// [plans] should already be newest-[WorkoutPlan.updatedAt] first.
/// [completedNewestFirst] is completed sessions only, newest [startedAt] first.
TodaySuggestion? suggestToday({
  required List<WorkoutPlan> plans,
  List<WorkoutSession> completedNewestFirst = const [],
  DateTime? now,
}) {
  WorkoutPlan? plan;
  for (final item in plans) {
    if (item.days.any((day) => dayCanStart(item, day))) {
      plan = item;
      break;
    }
  }
  if (plan == null) return null;

  final startable = [
    for (final day in plan.days)
      if (dayCanStart(plan, day)) day,
  ];
  if (startable.isEmpty) return null;

  WorkoutSession? lastForPlan;
  for (final session in completedNewestFirst) {
    if (session.planId == plan.uuid) {
      lastForPlan = session;
      break;
    }
  }

  final clock = now ?? DateTime.now();
  PlanDay day;
  var alreadyToday = false;
  if (lastForPlan == null) {
    day = startable.first;
  } else {
    final trainedThisDayToday = sameUtcDay(lastForPlan.startedAt, clock) &&
        startable.any((item) => item.dayId == lastForPlan!.planDayId);
    final lastIndex = startable.indexWhere(
      (item) => item.dayId == lastForPlan!.planDayId,
    );
    if (trainedThisDayToday) {
      alreadyToday = true;
      day = lastIndex < 0
          ? startable.first
          : startable[(lastIndex + 1) % startable.length];
    } else if (lastIndex < 0) {
      day = startable.first;
    } else {
      day = startable[(lastIndex + 1) % startable.length];
    }
  }

  final first = firstExerciseTitle(day, plan);
  if (lastForPlan == null) {
    return TodaySuggestion(
      plan: plan,
      day: day,
      alreadyTrainedToday: false,
      headline: 'Today: ${day.title}',
      prompt: 'Start with $first, then log what you did.',
    );
  }
  if (alreadyToday) {
    return TodaySuggestion(
      plan: plan,
      day: day,
      alreadyTrainedToday: true,
      headline: 'Next up: ${day.title}',
      prompt:
          'You already trained today. When you are ready, start with $first and log what you did.',
    );
  }
  return TodaySuggestion(
    plan: plan,
    day: day,
    alreadyTrainedToday: false,
    headline: 'Today: ${day.title}',
    prompt: 'Start with $first, then log what you did.',
  );
}

/// Plans, live session, and today's suggestion loaded from repositories.
class HomeOverview {
  const HomeOverview({
    required this.plans,
    this.live,
    this.today,
  });

  final List<WorkoutPlan> plans;
  final WorkoutSession? live;
  final TodaySuggestion? today;
}

/// One read for the home screen. Suggestion math stays [suggestToday].
Future<HomeOverview> loadHomeOverview({
  required PlanRepository plans,
  required SessionRepository sessions,
  DateTime? now,
}) async {
  final items = await plans.all();
  final live = await sessions.inProgress();
  final completed = await sessions.completedNewestFirst();
  return HomeOverview(
    plans: items,
    live: live,
    today: suggestToday(
      plans: items,
      completedNewestFirst: completed,
      now: now,
    ),
  );
}
