import '../domain/plan_catalog.dart';
import '../domain/plan_validation.dart';
import '../domain/models/workout_plan.dart';

/// Bundled exercise icons the day list and editor can match by name.
class ExerciseAssetEntry {
  const ExerciseAssetEntry({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.keywords,
    this.targetAreaIds = const [],
    this.goalIds = const [],
  });

  final String id;
  final String label;
  final String assetPath;
  final List<String> keywords;
  final List<String> targetAreaIds;
  final List<String> goalIds;

  /// Phrase used when matching titles, e.g. `kang squat`.
  String get phrase => id.replaceAll('-', ' ');

  /// Looping form demo for this movement.
  String get gifPath => '$exerciseAssetFolder/gifs/$id.gif';
}

const exerciseAssetFolder = 'assets/image/exercises';

ExerciseAssetEntry _asset(
  String id,
  String label,
  List<String> keywords, {
  List<String> targetAreaIds = const [],
  List<String> goalIds = const [],
}) {
  return ExerciseAssetEntry(
    id: id,
    label: label,
    assetPath: '$exerciseAssetFolder/$id.png',
    keywords: keywords,
    targetAreaIds: targetAreaIds,
    goalIds: goalIds,
  );
}

const _strengthMuscle = ['build-strength', 'build-muscle'];
const _muscle = ['build-muscle'];
const _muscleFitness = ['build-muscle', 'general-fitness'];
const _strength = ['build-strength'];
const _mobility = ['mobility'];
const _cardio = ['lose-weight', 'general-fitness'];
const _core = ['general-fitness', 'build-muscle'];

/// Thirty illustrated exercise stills and matching form GIFs.
final bundledExerciseAssets = <ExerciseAssetEntry>[
  _asset(
    'squat',
    'Squat',
    ['squat', 'back squat'],
    targetAreaIds: ['quads', 'glutes'],
    goalIds: [..._strengthMuscle, 'general-fitness'],
  ),
  _asset(
    'kang-squat',
    'Kang squat',
    ['kang', 'kang squat'],
    targetAreaIds: ['hamstrings', 'glutes', 'quads'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'front-squat',
    'Front squat',
    ['front squat'],
    targetAreaIds: ['quads', 'glutes'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'leg-extension',
    'Leg extension',
    ['leg extension', 'extension'],
    targetAreaIds: ['quads'],
    goalIds: _muscle,
  ),
  _asset(
    'lunge',
    'Lunge',
    ['lunge', 'lunges'],
    targetAreaIds: ['quads', 'glutes'],
    goalIds: _muscleFitness,
  ),
  _asset(
    'reverse-lunge-press',
    'Reverse lunge press',
    [
      'reverse lunge',
      'lunges+ press',
      'lunge press',
      'reverse lunges',
      'reverse lunges press',
    ],
    targetAreaIds: ['quads', 'glutes', 'front-shoulders'],
    goalIds: _muscleFitness,
  ),
  _asset(
    'deadlift',
    'Deadlift',
    ['deadlift'],
    targetAreaIds: ['hamstrings', 'glutes', 'upper-traps'],
    goalIds: _strength,
  ),
  _asset(
    'romanian-deadlift',
    'Romanian deadlift',
    ['romanian', 'rdl', 'romanian deadlift'],
    targetAreaIds: ['hamstrings', 'glutes'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'hip-thrust',
    'Hip thrust',
    ['hip thrust', 'glute bridge'],
    targetAreaIds: ['glutes'],
    goalIds: _muscle,
  ),
  _asset(
    'calf-raise',
    'Calf raise',
    ['calf', 'calves'],
    targetAreaIds: ['calves'],
    goalIds: _muscle,
  ),
  _asset(
    'bench-press',
    'Bench press',
    ['bench', 'bench press'],
    targetAreaIds: ['chest', 'triceps', 'front-shoulders'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'push-up',
    'Push up',
    ['push up', 'push-up', 'pushup'],
    targetAreaIds: ['chest', 'triceps', 'front-shoulders'],
    goalIds: _muscleFitness,
  ),
  _asset(
    'chest-fly',
    'Chest fly',
    ['fly', 'chest fly', 'pec fly'],
    targetAreaIds: ['chest'],
    goalIds: _muscle,
  ),
  _asset(
    'pull-up',
    'Pull up',
    ['pull up', 'pull-up', 'chin up'],
    targetAreaIds: ['lats', 'biceps', 'upper-back'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'lat-pulldown',
    'Lat pulldown',
    ['lat', 'pulldown', 'pull down'],
    targetAreaIds: ['lats', 'biceps'],
    goalIds: _muscle,
  ),
  _asset(
    'rowing',
    'Rowing',
    ['row', 'rowing', 'bent over row'],
    targetAreaIds: ['upper-back', 'lats', 'biceps'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'shoulder-press',
    'Shoulder press',
    ['shoulder press', 'overhead press', 'ohp'],
    targetAreaIds: ['front-shoulders', 'triceps'],
    goalIds: _strengthMuscle,
  ),
  _asset(
    'lateral-raise',
    'Lateral raise',
    ['lateral', 'side raise'],
    targetAreaIds: ['side-shoulders', 'upper-traps'],
    goalIds: _muscle,
  ),
  _asset(
    'bicep-curl',
    'Bicep curl',
    ['bicep', 'curl'],
    targetAreaIds: ['biceps', 'forearms'],
    goalIds: _muscle,
  ),
  _asset(
    'tricep-dip',
    'Tricep dip',
    ['tricep', 'dip', 'dips'],
    targetAreaIds: ['triceps', 'chest'],
    goalIds: _muscle,
  ),
  _asset(
    'plank',
    'Plank',
    ['plank'],
    targetAreaIds: ['abs', 'core'],
    goalIds: _core,
  ),
  _asset(
    'crunches',
    'Crunches',
    ['crunch', 'sit up', 'sit-up'],
    targetAreaIds: ['abs'],
    goalIds: _muscle,
  ),
  _asset(
    'bicycle-crunch',
    'Bicycle crunch',
    ['bicycle', 'bicycle crunch'],
    targetAreaIds: ['abs'],
    goalIds: _muscle,
  ),
  _asset(
    'russian-twist',
    'Russian twist',
    ['russian twist', 'twist'],
    targetAreaIds: ['abs', 'core'],
    goalIds: _muscle,
  ),
  _asset(
    'leg-raise',
    'Leg raise',
    ['leg raise', 'hanging leg'],
    targetAreaIds: ['abs'],
    goalIds: _muscle,
  ),
  _asset(
    'shoot-out',
    'Shoot out',
    ['shoot out', 'shootout'],
    targetAreaIds: ['abs'],
    goalIds: _muscle,
  ),
  _asset(
    'step-lunge-stretch',
    'Step lunge stretch',
    ['step lunge', 'lunge stretch', 'stretch'],
    targetAreaIds: ['hips', 'quads', 'hamstrings'],
    goalIds: _mobility,
  ),
  _asset(
    'kettlebell-swing',
    'Kettlebell swing',
    ['kettlebell', 'swing', 'kb swing'],
    targetAreaIds: ['glutes', 'hamstrings', 'full-body'],
    goalIds: ['build-strength', 'lose-weight'],
  ),
  _asset(
    'box-jump',
    'Box jump',
    ['box jump', 'jump'],
    targetAreaIds: ['quads', 'glutes'],
    goalIds: _cardio,
  ),
  _asset(
    'mountain-climber',
    'Mountain climber',
    ['mountain climber', 'climber'],
    targetAreaIds: ['abs', 'core', 'full-body'],
    goalIds: _cardio,
  ),
];

String normalizeExerciseTitle(String? raw) {
  if (raw == null) return '';
  return raw
      .toLowerCase()
      .replaceAll('+', ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Picks the bundled icon whose name or keywords best match [title].
ExerciseAssetEntry? matchExerciseAsset(String? title) {
  final haystack = normalizeExerciseTitle(title);
  if (haystack.isEmpty) return null;

  ExerciseAssetEntry? best;
  var bestScore = 0;
  for (final asset in bundledExerciseAssets) {
    final score = _score(haystack, asset);
    if (score > bestScore) {
      best = asset;
      bestScore = score;
    }
  }
  if (bestScore < 4) return null;
  return best;
}

ExerciseAssetEntry? bundledAssetByPath(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  for (final entry in bundledExerciseAssets) {
    if (entry.assetPath == path || entry.gifPath == path) return entry;
  }
  return null;
}

ExerciseAssetEntry? bestAssetMatchForTitle(String title) =>
    matchExerciseAsset(title);

/// Catalog target areas for a recognized title. Empty when unknown.
List<String> catalogTargetAreaIdsForTitle(String title) {
  final match = matchExerciseAsset(title);
  if (match == null) return const [];
  return canonicalizeTargetAreaIds(match.targetAreaIds);
}

/// True when [current] equals the catalog defaults for [title] (or both empty).
bool targetAreasMatchCatalog(String title, List<String> current) {
  return sameIdList(
    canonicalizeTargetAreaIds(current),
    catalogTargetAreaIdsForTitle(title),
  );
}

List<ExerciseAssetEntry> suggestedAssetsForTitle(String title) {
  final match = bestAssetMatchForTitle(title);
  if (match == null) return bundledExerciseAssets;
  final rest = bundledExerciseAssets.where((entry) => entry.id != match.id);
  return [match, ...rest];
}

/// Ranks catalog exercises for the add-exercise picker.
///
/// No goals: alphabetical by label. With goals: tagged matches first, then
/// the rest alphabetically.
List<ExerciseAssetEntry> suggestedExercisesForGoals(List<String> goalIds) {
  final goals = canonicalizeGoalIds(goalIds);
  final entries = [...bundledExerciseAssets]
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  if (goals.isEmpty) return entries;
  int score(ExerciseAssetEntry entry) {
    var n = 0;
    for (final id in entry.goalIds) {
      if (goals.contains(id)) n += 1;
    }
    return n;
  }

  entries.sort((a, b) {
    final delta = score(b) - score(a);
    if (delta != 0) return delta;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
  return entries;
}

/// Advisory Review notes. Never blocks Create plan.
List<PlanIssue> goalGuidanceFor(WorkoutPlan plan) {
  if (plan.goalIds.isEmpty) return const [];
  final usedGoalTags = <String>{};
  for (final day in plan.days) {
    for (final block in day.blocks) {
      for (final exercise in block.exercises) {
        final match = matchExerciseAsset(exercise.title);
        if (match == null) continue;
        usedGoalTags.addAll(match.goalIds);
      }
    }
  }
  final guidance = <PlanIssue>[];
  for (final goalId in canonicalizeGoalIds(plan.goalIds)) {
    if (usedGoalTags.contains(goalId)) continue;
    final label = planGoalLabel(goalId);
    final dayId = plan.days.isEmpty ? reviewStepKey : plan.days.first.dayId;
    guidance.add(
      PlanIssue(
        stepKey: dayId,
        message: 'No $label work yet. Add a matching exercise or leave the '
            'goal as a reminder.',
        required: false,
      ),
    );
  }
  return guidance;
}

int _score(String haystack, ExerciseAssetEntry asset) {
  final padded = ' $haystack ';
  final phrase = asset.phrase;
  if (haystack == phrase || haystack == asset.id) return 100 + phrase.length;
  var score = 0;
  if (padded.contains(' $phrase ')) {
    score = 80 + phrase.length;
  }
  for (final keyword in asset.keywords) {
    final needle = normalizeExerciseTitle(keyword);
    if (needle.isEmpty) continue;
    if (haystack == needle) {
      score = score < 90 + needle.length ? 90 + needle.length : score;
    } else if (padded.contains(' $needle ')) {
      final bump = 10 + needle.length;
      if (bump > score) score = bump;
    }
  }
  return score;
}
