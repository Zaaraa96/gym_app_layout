/// Bundled exercise icons the day list and editor can match by name.
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

  /// Phrase used when matching titles, e.g. `kang squat`.
  String get phrase => id.replaceAll('-', ' ');
}

const exerciseAssetFolder = 'assets/image/exercises';

ExerciseAssetEntry _asset(
  String id,
  String label,
  List<String> keywords,
) {
  return ExerciseAssetEntry(
    id: id,
    label: label,
    assetPath: '$exerciseAssetFolder/$id.svg',
    keywords: keywords,
  );
}

/// Thirty exercise icons designed for this app's deep-purple day rows.
final bundledExerciseAssets = <ExerciseAssetEntry>[
  _asset('squat', 'Squat', ['squat', 'back squat']),
  _asset('kang-squat', 'Kang squat', ['kang', 'kang squat']),
  _asset('front-squat', 'Front squat', ['front squat']),
  _asset('leg-extension', 'Leg extension', ['leg extension', 'extension']),
  _asset('lunge', 'Lunge', ['lunge', 'lunges']),
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
  ),
  _asset('deadlift', 'Deadlift', ['deadlift']),
  _asset(
    'romanian-deadlift',
    'Romanian deadlift',
    ['romanian', 'rdl', 'romanian deadlift'],
  ),
  _asset('hip-thrust', 'Hip thrust', ['hip thrust', 'glute bridge']),
  _asset('calf-raise', 'Calf raise', ['calf', 'calves']),
  _asset('bench-press', 'Bench press', ['bench', 'bench press']),
  _asset('push-up', 'Push up', ['push up', 'push-up', 'pushup']),
  _asset('chest-fly', 'Chest fly', ['fly', 'chest fly', 'pec fly']),
  _asset('pull-up', 'Pull up', ['pull up', 'pull-up', 'chin up']),
  _asset('lat-pulldown', 'Lat pulldown', ['lat', 'pulldown', 'pull down']),
  _asset('rowing', 'Rowing', ['row', 'rowing', 'bent over row']),
  _asset(
    'shoulder-press',
    'Shoulder press',
    ['shoulder press', 'overhead press', 'ohp'],
  ),
  _asset('lateral-raise', 'Lateral raise', ['lateral', 'side raise']),
  _asset('bicep-curl', 'Bicep curl', ['bicep', 'curl']),
  _asset('tricep-dip', 'Tricep dip', ['tricep', 'dip', 'dips']),
  _asset('plank', 'Plank', ['plank']),
  _asset('crunches', 'Crunches', ['crunch', 'sit up', 'sit-up']),
  _asset(
    'bicycle-crunch',
    'Bicycle crunch',
    ['bicycle', 'bicycle crunch'],
  ),
  _asset('russian-twist', 'Russian twist', ['russian twist', 'twist']),
  _asset('leg-raise', 'Leg raise', ['leg raise', 'hanging leg']),
  _asset('shoot-out', 'Shoot out', ['shoot out', 'shootout']),
  _asset(
    'step-lunge-stretch',
    'Step lunge stretch',
    ['step lunge', 'lunge stretch', 'stretch'],
  ),
  _asset(
    'kettlebell-swing',
    'Kettlebell swing',
    ['kettlebell', 'swing', 'kb swing'],
  ),
  _asset('box-jump', 'Box jump', ['box jump', 'jump']),
  _asset(
    'mountain-climber',
    'Mountain climber',
    ['mountain climber', 'climber'],
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
