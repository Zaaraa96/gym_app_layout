/// Bundled exercise preview assets the user can pick when editing a block.
class ExerciseAssetEntry {
  const ExerciseAssetEntry({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.keywords,
  });

  final String id;
  final String label;
  final String assetPath;
  final List<String> keywords;
}

const exerciseAssetFolder = 'assets/image/exercises';

/// Thirty common exercise SVG icons shipped with the app.
const bundledExerciseAssets = <ExerciseAssetEntry>[
  ExerciseAssetEntry(
    id: 'bench-press',
    label: 'Bench press',
    assetPath: '$exerciseAssetFolder/bench-press.svg',
    keywords: ['bench', 'press', 'chest', 'barbell'],
  ),
  ExerciseAssetEntry(
    id: 'squat',
    label: 'Squat',
    assetPath: '$exerciseAssetFolder/squat.svg',
    keywords: ['squat', 'legs', 'barbell'],
  ),
  ExerciseAssetEntry(
    id: 'deadlift',
    label: 'Deadlift',
    assetPath: '$exerciseAssetFolder/deadlift.svg',
    keywords: ['deadlift', 'hinge', 'barbell'],
  ),
  ExerciseAssetEntry(
    id: 'pull-up',
    label: 'Pull up',
    assetPath: '$exerciseAssetFolder/pull-up.svg',
    keywords: ['pull', 'chin', 'back'],
  ),
  ExerciseAssetEntry(
    id: 'push-up',
    label: 'Push up',
    assetPath: '$exerciseAssetFolder/push-up.svg',
    keywords: ['push', 'press', 'chest', 'bodyweight'],
  ),
  ExerciseAssetEntry(
    id: 'shoulder-press',
    label: 'Shoulder press',
    assetPath: '$exerciseAssetFolder/shoulder-press.svg',
    keywords: ['shoulder', 'overhead', 'press'],
  ),
  ExerciseAssetEntry(
    id: 'bicep-curl',
    label: 'Bicep curl',
    assetPath: '$exerciseAssetFolder/bicep-curl.svg',
    keywords: ['bicep', 'curl', 'arms'],
  ),
  ExerciseAssetEntry(
    id: 'tricep-dip',
    label: 'Tricep dip',
    assetPath: '$exerciseAssetFolder/tricep-dip.svg',
    keywords: ['tricep', 'dip', 'arms'],
  ),
  ExerciseAssetEntry(
    id: 'lunge',
    label: 'Lunge',
    assetPath: '$exerciseAssetFolder/lunge.svg',
    keywords: ['lunge', 'legs', 'split'],
  ),
  ExerciseAssetEntry(
    id: 'plank',
    label: 'Plank',
    assetPath: '$exerciseAssetFolder/plank.svg',
    keywords: ['plank', 'core', 'hold'],
  ),
  ExerciseAssetEntry(
    id: 'burpee',
    label: 'Burpee',
    assetPath: '$exerciseAssetFolder/burpee.svg',
    keywords: ['burpee', 'cardio', 'full body'],
  ),
  ExerciseAssetEntry(
    id: 'rowing',
    label: 'Rowing',
    assetPath: '$exerciseAssetFolder/rowing.svg',
    keywords: ['row', 'cable', 'back'],
  ),
  ExerciseAssetEntry(
    id: 'lat-pulldown',
    label: 'Lat pulldown',
    assetPath: '$exerciseAssetFolder/lat-pulldown.svg',
    keywords: ['lat', 'pulldown', 'back'],
  ),
  ExerciseAssetEntry(
    id: 'leg-press',
    label: 'Leg press',
    assetPath: '$exerciseAssetFolder/leg-press.svg',
    keywords: ['leg', 'press', 'machine'],
  ),
  ExerciseAssetEntry(
    id: 'calf-raise',
    label: 'Calf raise',
    assetPath: '$exerciseAssetFolder/calf-raise.svg',
    keywords: ['calf', 'raise', 'legs'],
  ),
  ExerciseAssetEntry(
    id: 'chest-fly',
    label: 'Chest fly',
    assetPath: '$exerciseAssetFolder/chest-fly.svg',
    keywords: ['fly', 'chest', 'dumbbell'],
  ),
  ExerciseAssetEntry(
    id: 'lateral-raise',
    label: 'Lateral raise',
    assetPath: '$exerciseAssetFolder/lateral-raise.svg',
    keywords: ['lateral', 'shoulder', 'raise'],
  ),
  ExerciseAssetEntry(
    id: 'front-squat',
    label: 'Front squat',
    assetPath: '$exerciseAssetFolder/front-squat.svg',
    keywords: ['front', 'squat', 'legs'],
  ),
  ExerciseAssetEntry(
    id: 'romanian-deadlift',
    label: 'Romanian deadlift',
    assetPath: '$exerciseAssetFolder/romanian-deadlift.svg',
    keywords: ['rdl', 'romanian', 'deadlift', 'hinge'],
  ),
  ExerciseAssetEntry(
    id: 'hip-thrust',
    label: 'Hip thrust',
    assetPath: '$exerciseAssetFolder/hip-thrust.svg',
    keywords: ['hip', 'thrust', 'glute'],
  ),
  ExerciseAssetEntry(
    id: 'kettlebell-swing',
    label: 'Kettlebell swing',
    assetPath: '$exerciseAssetFolder/kettlebell-swing.svg',
    keywords: ['kettlebell', 'swing', 'cardio'],
  ),
  ExerciseAssetEntry(
    id: 'mountain-climber',
    label: 'Mountain climber',
    assetPath: '$exerciseAssetFolder/mountain-climber.svg',
    keywords: ['mountain', 'climber', 'core', 'cardio'],
  ),
  ExerciseAssetEntry(
    id: 'jumping-jack',
    label: 'Jumping jack',
    assetPath: '$exerciseAssetFolder/jumping-jack.svg',
    keywords: ['jumping', 'jack', 'cardio', 'warmup'],
  ),
  ExerciseAssetEntry(
    id: 'crunches',
    label: 'Crunches',
    assetPath: '$exerciseAssetFolder/crunches.svg',
    keywords: ['crunch', 'abs', 'core'],
  ),
  ExerciseAssetEntry(
    id: 'leg-raise',
    label: 'Leg raise',
    assetPath: '$exerciseAssetFolder/leg-raise.svg',
    keywords: ['leg', 'raise', 'abs', 'core'],
  ),
  ExerciseAssetEntry(
    id: 'bicycle-crunch',
    label: 'Bicycle crunch',
    assetPath: '$exerciseAssetFolder/bicycle-crunch.svg',
    keywords: ['bicycle', 'crunch', 'abs'],
  ),
  ExerciseAssetEntry(
    id: 'russian-twist',
    label: 'Russian twist',
    assetPath: '$exerciseAssetFolder/russian-twist.svg',
    keywords: ['russian', 'twist', 'core', 'oblique'],
  ),
  ExerciseAssetEntry(
    id: 'box-jump',
    label: 'Box jump',
    assetPath: '$exerciseAssetFolder/box-jump.svg',
    keywords: ['box', 'jump', 'plyo', 'legs'],
  ),
  ExerciseAssetEntry(
    id: 'battle-rope',
    label: 'Battle rope',
    assetPath: '$exerciseAssetFolder/battle-rope.svg',
    keywords: ['battle', 'rope', 'cardio'],
  ),
  ExerciseAssetEntry(
    id: 'treadmill-run',
    label: 'Treadmill run',
    assetPath: '$exerciseAssetFolder/treadmill-run.svg',
    keywords: ['treadmill', 'run', 'cardio'],
  ),
];

ExerciseAssetEntry? bundledAssetByPath(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  for (final entry in bundledExerciseAssets) {
    if (entry.assetPath == path) return entry;
  }
  return null;
}

ExerciseAssetEntry? bestAssetMatchForTitle(String title) {
  final query = title.trim().toLowerCase();
  if (query.isEmpty) return null;

  for (final entry in bundledExerciseAssets) {
    if (entry.label.toLowerCase().contains(query)) return entry;
    if (entry.id.replaceAll('-', ' ').contains(query)) return entry;
    for (final keyword in entry.keywords) {
      if (query.contains(keyword)) return entry;
    }
  }
  return null;
}

List<ExerciseAssetEntry> suggestedAssetsForTitle(String title) {
  final match = bestAssetMatchForTitle(title);
  if (match == null) return bundledExerciseAssets;
  final rest = bundledExerciseAssets.where((entry) => entry.id != match.id);
  return [match, ...rest];
}
