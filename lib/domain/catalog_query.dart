import '../common/exercise_asset_catalog.dart';
import 'models/catalog_exercise.dart';
import 'models/enums.dart';
import 'plan_catalog.dart';

/// Filters the merged catalog. Region chips are a union; muscle chips further
/// restrict that set. Empty selections mean "all".
List<CatalogExercise> filterCatalogExercises(
  Iterable<CatalogExercise> items, {
  String query = '',
  Set<String> regionIds = const {},
  Set<String> targetAreaIds = const {},
}) {
  final needle = normalizeExerciseTitle(query);
  final regions = canonicalizeRegionIds(regionIds).toSet();
  final muscles = canonicalizeTargetAreaIds(targetAreaIds).toSet();
  final result = <CatalogExercise>[];
  for (final item in items) {
    if (!item.hasPicture) continue;
    if (regions.isNotEmpty &&
        item.regionIds.every((id) => !regions.contains(id))) {
      continue;
    }
    if (muscles.isNotEmpty &&
        item.targetAreaIds.every((id) => !muscles.contains(id))) {
      continue;
    }
    if (needle.isNotEmpty && !_matchesQuery(item, needle)) continue;
    result.add(item);
  }
  result.sort(
    (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  );
  return result;
}

bool _matchesQuery(CatalogExercise item, String needle) {
  if (normalizeExerciseTitle(item.title).contains(needle)) return true;
  if (normalizeExerciseTitle(item.id).contains(needle)) return true;
  for (final alias in item.aliases) {
    if (normalizeExerciseTitle(alias).contains(needle)) return true;
  }
  return false;
}

int scoreCatalogTitle(String haystack, CatalogExercise exercise) {
  final padded = ' $haystack ';
  final phrase = normalizeExerciseTitle(exercise.title);
  final idPhrase = exercise.id.replaceAll('-', ' ');
  if (haystack == phrase || haystack == exercise.id || haystack == idPhrase) {
    return 100 + phrase.length;
  }
  var score = 0;
  if (phrase.isNotEmpty && padded.contains(' $phrase ')) {
    score = 80 + phrase.length;
  }
  if (idPhrase.isNotEmpty && padded.contains(' $idPhrase ')) {
    final bump = 80 + idPhrase.length;
    if (bump > score) score = bump;
  }
  for (final keyword in exercise.aliases) {
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

CatalogExercise? bestCatalogMatch(
  String? title,
  Iterable<CatalogExercise> items, {
  int minScore = 4,
}) {
  final haystack = normalizeExerciseTitle(title);
  if (haystack.isEmpty) return null;
  CatalogExercise? best;
  var bestScore = 0;
  for (final item in items) {
    final score = scoreCatalogTitle(haystack, item);
    if (score > bestScore) {
      best = item;
      bestScore = score;
    }
  }
  if (bestScore < minScore) return null;
  return best;
}

/// True when [title] equals a bundled catalog id, label, or alias.
bool titleMatchesBundledCatalog(String? title) {
  final haystack = normalizeExerciseTitle(title);
  if (haystack.isEmpty) return false;
  for (final asset in bundledExerciseAssets) {
    if (haystack == asset.id ||
        haystack == asset.phrase ||
        haystack == normalizeExerciseTitle(asset.label)) {
      return true;
    }
    for (final keyword in asset.keywords) {
      if (haystack == normalizeExerciseTitle(keyword)) return true;
    }
  }
  return false;
}

/// User-created rows that a later app version can harvest into the bundled list.
bool isPromotionCandidate(CatalogExercise exercise) {
  if (exercise.origin != CatalogOrigin.user) return false;
  if (titleMatchesBundledCatalog(exercise.title)) return false;
  for (final alias in exercise.aliases) {
    if (titleMatchesBundledCatalog(alias)) return false;
  }
  return true;
}
