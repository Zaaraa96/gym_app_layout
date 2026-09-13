import '../../domain/models/models.dart';
import '../plans/day_card_summary.dart';

/// Quiet session progress for the live header: `3 of 8 · ~12 min left`.
class LiveSessionProgress {
  const LiveSessionProgress({
    required this.currentOrdinal,
    required this.totalMovements,
    required this.remainingSeconds,
  });

  /// 1-based index of the movement in focus (completed + 1 while work remains).
  final int currentOrdinal;
  final int totalMovements;
  final int remainingSeconds;

  String get line {
    if (totalMovements <= 0) return '';
    final left = formatEstimatedDuration(remainingSeconds);
    if (left.isEmpty) return '$currentOrdinal of $totalMovements';
    return '$currentOrdinal of $totalMovements · $left left';
  }
}

/// Progress across [session] logs. Uses the same work/rest assumptions as day cards.
LiveSessionProgress liveSessionProgress(WorkoutSession session) {
  final logs = session.exerciseLogs;
  final total = logs.length;
  if (total == 0) {
    return const LiveSessionProgress(
      currentOrdinal: 0,
      totalMovements: 0,
      remainingSeconds: 0,
    );
  }

  var completed = 0;
  for (final log in logs) {
    if (log.isComplete) completed++;
  }
  final current = completed >= total ? total : completed + 1;
  return LiveSessionProgress(
    currentOrdinal: current,
    totalMovements: total,
    remainingSeconds: estimatedRemainingSessionSeconds(logs),
  );
}

/// Remaining prescribed work + assumed rest for incomplete logs.
int estimatedRemainingSessionSeconds(List<ExerciseLog> logs) {
  if (logs.isEmpty) return 0;

  final byBlock = <String, List<ExerciseLog>>{};
  for (final log in logs) {
    if (log.isComplete) continue;
    byBlock.putIfAbsent(log.blockId, () => []).add(log);
  }
  if (byBlock.isEmpty) return 0;

  var total = 0;
  var blockIndex = 0;
  for (final blockLogs in byBlock.values) {
    if (blockIndex > 0) total += 30; // between blocks (day-card constant)
    total += _remainingBlockSeconds(blockLogs);
    blockIndex++;
  }
  return total;
}

int _remainingBlockSeconds(List<ExerciseLog> blockLogs) {
  if (blockLogs.isEmpty) return 0;
  final isSuperset =
      blockLogs.length > 1 || blockLogs.first.blockKind == BlockKind.superset;
  if (isSuperset) {
    var roundWork = 0;
    var maxRemainingSets = 0;
    for (final log in blockLogs) {
      final left = log.prescribedSets - log.sets.length;
      if (left <= 0) continue;
      if (left > maxRemainingSets) maxRemainingSets = left;
      roundWork += _workSecondsForLog(log, sets: 1);
    }
    if (maxRemainingSets <= 0) return 0;
    var total = roundWork * maxRemainingSets;
    if (maxRemainingSets > 1) total += (maxRemainingSets - 1) * 60;
    return total;
  }

  var total = 0;
  for (final log in blockLogs) {
    final left = log.prescribedSets - log.sets.length;
    if (left <= 0) continue;
    total += _workSecondsForLog(log, sets: left);
    if (left > 1) total += (left - 1) * 60;
  }
  return total;
}

int _workSecondsForLog(ExerciseLog log, {required int sets}) {
  final duration = log.prescribedDurationSeconds;
  if (duration != null) return sets * duration;
  final reps = log.prescribedReps ?? 0;
  final perSet = reps * 3;
  final bounded = perSet < 20 ? 20 : perSet;
  return sets * bounded;
}

/// One concrete line for the ended screen, e.g. `3 sets of Kang squat saved`.
String sessionSavedSummary(WorkoutSession session) {
  ExerciseLog? best;
  for (final log in session.exerciseLogs) {
    if (log.sets.isEmpty) continue;
    if (best == null || log.sets.length >= best.sets.length) {
      best = log;
    }
  }
  if (best == null) return 'What you logged is saved.';
  final n = best.sets.length;
  final word = n == 1 ? 'set' : 'sets';
  return '$n $word of ${best.exerciseTitle} saved';
}
