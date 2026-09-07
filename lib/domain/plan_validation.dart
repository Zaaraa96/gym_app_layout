import 'models/enums.dart';
import 'models/workout_plan.dart';
import 'plan_catalog.dart';

/// A required or advisory finding the builder and Review can navigate to.
class PlanIssue {
  const PlanIssue({
    required this.stepKey,
    required this.message,
    this.required = true,
  });

  /// `details`, a [PlanDay.dayId], or `review`.
  final String stepKey;
  final String message;
  final bool required;
}

/// Visual treatment for one stepper row. Color is never the only signal.
enum BuilderStepVisual { complete, current, incomplete, untouched }

enum BuilderStepKind { details, day, review }

class BuilderStep {
  const BuilderStep({
    required this.kind,
    required this.key,
    required this.title,
    this.dayId,
  });

  final BuilderStepKind kind;
  final String key;
  final String title;
  final String? dayId;
}

const detailsStepKey = 'details';
const reviewStepKey = 'review';

List<BuilderStep> builderStepsFor(WorkoutPlan plan) {
  return [
    const BuilderStep(
      kind: BuilderStepKind.details,
      key: detailsStepKey,
      title: 'Plan details',
    ),
    for (var i = 0; i < plan.days.length; i++)
      BuilderStep(
        kind: BuilderStepKind.day,
        key: plan.days[i].dayId,
        title: plan.days[i].title.trim().isEmpty
            ? 'Day ${i + 1}'
            : plan.days[i].title.trim(),
        dayId: plan.days[i].dayId,
      ),
    const BuilderStep(
      kind: BuilderStepKind.review,
      key: reviewStepKey,
      title: 'Review & create',
    ),
  ];
}

bool detailsIsComplete(WorkoutPlan plan) => plan.title.trim().isNotEmpty;

bool detailsIsUntouched(WorkoutPlan plan) =>
    plan.title.trim().isEmpty &&
    plan.description.trim().isEmpty &&
    plan.goalIds.isEmpty;

bool dayIsUntouched(PlanDay day, int index) {
  final defaultTitle = 'Day ${index + 1}';
  return day.title.trim() == defaultTitle &&
      day.summary.trim().isEmpty &&
      day.blocks.isEmpty;
}

bool dayIsComplete(PlanDay day) => issuesForDay(day).isEmpty;

List<PlanIssue> issuesForDay(PlanDay day, {String? stepKey}) {
  final key = stepKey ?? day.dayId;
  final issues = <PlanIssue>[];
  if (day.title.trim().isEmpty) {
    issues.add(
      PlanIssue(stepKey: key, message: 'Add a name for this day.'),
    );
  }
  if (day.blocks.isEmpty) {
    issues.add(
      PlanIssue(stepKey: key, message: 'Add at least one exercise.'),
    );
    return issues;
  }
  for (var i = 0; i < day.blocks.length; i++) {
    issues.addAll(issuesForBlock(day.blocks[i], stepKey: key, index: i));
  }
  return issues;
}

List<PlanIssue> issuesForBlock(
  ExerciseBlock block, {
  required String stepKey,
  required int index,
}) {
  final issues = <PlanIssue>[];
  final where = 'Block ${index + 1}';
  if (block.kind == BlockKind.single && block.exercises.length != 1) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$where must contain exactly one exercise.',
      ),
    );
  }
  if (block.kind == BlockKind.superset && block.exercises.length < 2) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$where is a superset and needs at least two exercises.',
      ),
    );
  }
  for (final exercise in block.exercises) {
    issues.addAll(issuesForExercise(exercise, stepKey: stepKey));
  }
  return issues;
}

List<PlanIssue> issuesForExercise(
  ExercisePrescription exercise, {
  required String stepKey,
}) {
  final issues = <PlanIssue>[];
  final title = exercise.title.trim();
  final named = title.isEmpty ? 'This exercise' : '"$title"';
  if (title.isEmpty) {
    issues.add(
      PlanIssue(stepKey: stepKey, message: 'Add a name for every exercise.'),
    );
  }
  if (exercise.prescribedSets < 1) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$named needs at least 1 set.',
      ),
    );
  }
  final reps = exercise.prescribedReps;
  final duration = exercise.prescribedDurationSeconds;
  if (reps != null && duration != null) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$named must use either reps or duration, not both.',
      ),
    );
  } else if (reps == null && duration == null) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$named needs reps or duration greater than zero.',
      ),
    );
  } else if (reps != null && reps < 1) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$named reps must be at least 1.',
      ),
    );
  } else if (duration != null && duration < 1) {
    issues.add(
      PlanIssue(
        stepKey: stepKey,
        message: '$named duration must be at least 1 second.',
      ),
    );
  }
  return issues;
}

List<PlanIssue> requiredIssuesFor(WorkoutPlan plan) {
  final issues = <PlanIssue>[];
  if (!detailsIsComplete(plan)) {
    issues.add(
      const PlanIssue(
        stepKey: detailsStepKey,
        message: 'Add a plan name.',
      ),
    );
  }
  if (plan.days.isEmpty) {
    issues.add(
      const PlanIssue(
        stepKey: reviewStepKey,
        message: 'Add at least one day.',
      ),
    );
    return issues;
  }
  for (final day in plan.days) {
    issues.addAll(issuesForDay(day));
  }
  return issues;
}

bool planCanActivate(WorkoutPlan plan) => requiredIssuesFor(plan).isEmpty;

BuilderStepVisual visualForStep({
  required BuilderStep step,
  required WorkoutPlan plan,
  required int currentIndex,
  required int stepIndex,
}) {
  if (stepIndex == currentIndex) return BuilderStepVisual.current;
  switch (step.kind) {
    case BuilderStepKind.details:
      if (detailsIsComplete(plan)) return BuilderStepVisual.complete;
      if (detailsIsUntouched(plan)) return BuilderStepVisual.untouched;
      return BuilderStepVisual.incomplete;
    case BuilderStepKind.day:
      final index = plan.days.indexWhere((day) => day.dayId == step.dayId);
      if (index < 0) return BuilderStepVisual.untouched;
      final day = plan.days[index];
      if (dayIsComplete(day)) return BuilderStepVisual.complete;
      if (dayIsUntouched(day, index)) return BuilderStepVisual.untouched;
      return BuilderStepVisual.incomplete;
    case BuilderStepKind.review:
      if (planCanActivate(plan)) return BuilderStepVisual.complete;
      if (currentIndex < stepIndex &&
          requiredIssuesFor(plan).every((issue) => issue.stepKey != reviewStepKey)) {
        // Not opened yet and earlier steps still incomplete.
        final earlierIncomplete = !detailsIsComplete(plan) ||
            plan.days.any((day) => !dayIsComplete(day));
        if (earlierIncomplete) return BuilderStepVisual.untouched;
      }
      return BuilderStepVisual.incomplete;
  }
}

/// Next incomplete required step, or Review when every preceding step is ready.
int nextIncompleteStepIndex(WorkoutPlan plan, int fromIndex) {
  final steps = builderStepsFor(plan);
  for (var i = fromIndex + 1; i < steps.length; i++) {
    final step = steps[i];
    if (step.kind == BuilderStepKind.review) return i;
    if (step.kind == BuilderStepKind.details && !detailsIsComplete(plan)) {
      return i;
    }
    if (step.kind == BuilderStepKind.day) {
      final day = plan.days.firstWhere((item) => item.dayId == step.dayId);
      if (!dayIsComplete(day)) return i;
    }
  }
  return steps.length - 1;
}

int firstIncompleteStepIndex(WorkoutPlan plan) {
  final steps = builderStepsFor(plan);
  if (!detailsIsComplete(plan)) return 0;
  for (var i = 0; i < plan.days.length; i++) {
    if (!dayIsComplete(plan.days[i])) return i + 1;
  }
  return steps.length - 1;
}

String subtitleForStep({
  required BuilderStep step,
  required WorkoutPlan plan,
  required BuilderStepVisual visual,
}) {
  switch (step.kind) {
    case BuilderStepKind.details:
      if (visual == BuilderStepVisual.complete) {
        final days = plan.days.length;
        return '${plan.displayTitle} · $days '
            '${days == 1 ? 'day' : 'days'}';
      }
      if (visual == BuilderStepVisual.incomplete) {
        return 'Add a plan name.';
      }
      return 'Name, description, and goals';
    case BuilderStepKind.day:
      PlanDay? day;
      for (final item in plan.days) {
        if (item.dayId == step.dayId) {
          day = item;
          break;
        }
      }
      if (day == null) return 'Add exercises and supersets';
      if (visual == BuilderStepVisual.incomplete) {
        final issues = issuesForDay(day);
        return issues.isEmpty
            ? 'Add at least one exercise.'
            : issues.first.message;
      }
      if (visual == BuilderStepVisual.complete) {
        return _dayCounts(day);
      }
      return 'Add exercises and supersets';
    case BuilderStepKind.review:
      final count = requiredIssuesFor(plan).length;
      if (count == 0) return 'Ready to create';
      if (visual == BuilderStepVisual.untouched) return 'Not ready yet';
      return count == 1
          ? '1 item still needs attention'
          : '$count items still need attention';
  }
}

String _dayCounts(PlanDay day) {
  var exercises = 0;
  var supersets = 0;
  for (final block in day.blocks) {
    if (block.kind == BlockKind.superset) {
      supersets += 1;
      exercises += block.exercises.length;
    } else {
      exercises += block.exercises.length;
    }
  }
  final exerciseLabel =
      '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}';
  if (supersets == 0) return exerciseLabel;
  return '$exerciseLabel · $supersets '
      '${supersets == 1 ? 'superset' : 'supersets'}';
}

int totalExerciseCount(WorkoutPlan plan) {
  var count = 0;
  for (final day in plan.days) {
    for (final block in day.blocks) {
      count += block.exercises.length;
    }
  }
  return count;
}

List<String> uniqueTargetAreaIdsForDay(PlanDay day) {
  final ids = <String>[];
  for (final block in day.blocks) {
    for (final exercise in block.exercises) {
      ids.addAll(exercise.targetAreaIds);
    }
  }
  return canonicalizeTargetAreaIds(ids);
}
