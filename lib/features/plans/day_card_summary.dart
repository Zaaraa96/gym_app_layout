import '../../common/exercise_asset_catalog.dart';
import '../../domain/models/models.dart';
import '../../domain/plan_catalog.dart';
import 'exercise_media.dart';

/// Auto-advance delay for day-card exercise thumbnails.
const dayCardThumbnailInterval = Duration(seconds: 3);

const _secondsPerRep = 3;
const _minSecondsPerSet = 20;
const _restBetweenSetsSeconds = 60;
const _transitionBetweenBlocksSeconds = 30;
const _maxTargetChips = 3;

const _pushAreas = {
  'chest',
  'triceps',
  'front-shoulders',
};
const _pullAreas = {
  'lats',
  'biceps',
  'upper-back',
  'rear-shoulders',
  'upper-traps',
  'forearms',
};
const _legsAreas = {
  'quads',
  'glutes',
  'hamstrings',
  'calves',
  'hips',
};
const _coreAreas = {'abs', 'core'};
const _shoulderAreas = {'side-shoulders'};
const _fullBodyAreas = {'full-body'};

/// How many movements are on [day], counting each superset partner.
int dayMovementCount(PlanDay day) {
  var count = 0;
  for (final block in day.blocks) {
    count += block.exercises.length;
  }
  return count;
}

/// Compact volume line: `1 exercise · 3 sets` or `4 exercises`.
String dayVolumeLabel(PlanDay day) {
  final n = dayMovementCount(day);
  if (n == 0) return 'No exercises yet';
  final noun = n == 1 ? 'exercise' : 'exercises';
  if (n == 1) {
    final sets = day.blocks.first.exercises.first.prescribedSets;
    if (sets > 0) return '1 exercise · $sets sets';
  }
  return '$n $noun';
}

/// Target areas shown on the card. Stored ids win; catalog fills gaps.
List<String> dayCardTargetAreaIds(PlanDay day) {
  final ids = <String>[];
  for (final block in day.blocks) {
    for (final exercise in block.exercises) {
      if (exercise.targetAreaIds.isNotEmpty) {
        ids.addAll(exercise.targetAreaIds);
      } else {
        ids.addAll(catalogTargetAreaIdsForTitle(exercise.title));
      }
    }
  }
  return canonicalizeTargetAreaIds(ids);
}

/// First [max] target ids, in catalog order.
List<String> dayCardVisibleTargetAreaIds(
  PlanDay day, {
  int max = _maxTargetChips,
}) {
  return dayCardTargetAreaIds(day).take(max).toList();
}

int dayCardHiddenTargetAreaCount(PlanDay day, {int max = _maxTargetChips}) {
  final n = dayCardTargetAreaIds(day).length - max;
  return n < 0 ? 0 : n;
}

/// Optional one-line focus. Summary wins; otherwise a muscle cluster.
///
/// Skips a derived cluster when the day title already names the session
/// (`Day 1 — Squat and push`).
String? dayFocusLabel(PlanDay day) {
  final summary = day.summary.trim();
  if (summary.isNotEmpty) return _firstLine(summary);
  if (_titleAlreadyNamesFocus(day.title)) return null;
  return focusFromTargetAreas(dayCardTargetAreaIds(day));
}

/// Push / Pull / Legs / Core cluster from catalog ids. Null when unknown.
String? focusFromTargetAreas(Iterable<String> ids) {
  final areas = canonicalizeTargetAreaIds(ids);
  if (areas.isEmpty) return null;
  final clusters = <String>[];
  bool hit(Set<String> group) => areas.any(group.contains);
  if (hit(_pushAreas)) clusters.add('Push');
  if (hit(_pullAreas)) clusters.add('Pull');
  if (hit(_legsAreas)) clusters.add('Legs');
  if (hit(_coreAreas)) clusters.add('Core');
  if (hit(_shoulderAreas)) clusters.add('Shoulders');
  if (hit(_fullBodyAreas)) clusters.add('Full body');
  if (clusters.isEmpty) return null;
  if (clusters.length > 2) return 'Mixed';
  return clusters.join(' · ');
}

/// Work + assumed rest, in seconds. Empty days are 0.
///
/// Rest is not stored (live rest is a manual stopwatch). The estimate uses
/// 60s between sets and 30s between blocks so the card can show a round
/// `~N min` without pretending to be a clock.
int estimatedDaySeconds(PlanDay day) {
  if (day.blocks.isEmpty) return 0;
  var total = 0;
  for (var i = 0; i < day.blocks.length; i++) {
    if (i > 0) total += _transitionBetweenBlocksSeconds;
    total += _blockSeconds(day.blocks[i]);
  }
  return total;
}

/// Rounded estimate, empty when the day has no work.
String formatEstimatedDuration(int seconds) {
  if (seconds <= 0) return '';
  final minutes = (seconds / 60).round();
  final clamped = minutes < 1 ? 1 : minutes;
  if (clamped < 3) return '~$clamped min';
  final rounded = ((clamped + 4) ~/ 5) * 5;
  final shown = rounded < 5 ? 5 : rounded;
  return '~$shown min';
}

String dayEstimateLabel(PlanDay day) =>
    formatEstimatedDuration(estimatedDaySeconds(day));

/// Catalog or stored stills for the card. Skips the generic fallback SVG.
List<ExerciseMediaRef> dayCardThumbnails(PlanDay day) {
  final seen = <String>{};
  final result = <ExerciseMediaRef>[];
  for (final block in day.blocks) {
    for (final exercise in block.exercises) {
      final media = resolveExerciseMedia(exercise);
      if (media == null) continue;
      if (media.uri == defaultBlockSvg) continue;
      if (!seen.add(media.uri)) continue;
      result.add(media);
    }
  }
  return result;
}

int _blockSeconds(ExerciseBlock block) {
  if (block.exercises.isEmpty) return 0;
  if (block.kind == BlockKind.superset) {
    final sets = block.exercises.first.prescribedSets;
    var roundWork = 0;
    for (final exercise in block.exercises) {
      roundWork += _workSeconds(exercise, sets: 1);
    }
    var total = roundWork * sets;
    if (sets > 1) total += (sets - 1) * _restBetweenSetsSeconds;
    return total;
  }
  var total = 0;
  for (final exercise in block.exercises) {
    total += _workSeconds(exercise, sets: exercise.prescribedSets);
    if (exercise.prescribedSets > 1) {
      total += (exercise.prescribedSets - 1) * _restBetweenSetsSeconds;
    }
  }
  return total;
}

int _workSeconds(ExercisePrescription exercise, {required int sets}) {
  final duration = exercise.prescribedDurationSeconds;
  if (duration != null) return sets * duration;
  final reps = exercise.prescribedReps ?? 0;
  final perSet = reps * _secondsPerRep;
  final bounded = perSet < _minSecondsPerSet ? _minSecondsPerSet : perSet;
  return sets * bounded;
}

bool _titleAlreadyNamesFocus(String title) {
  final stripped = title
      .trim()
      .replaceFirst(RegExp(r'^day\s+\d+\s*[-—·:]*\s*', caseSensitive: false), '')
      .trim();
  return stripped.isNotEmpty;
}

String _firstLine(String text) {
  final line = text.split(RegExp(r'[\r\n]+')).first.trim();
  if (line.length <= 48) return line;
  return '${line.substring(0, 45).trimRight()}…';
}
