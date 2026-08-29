import '../../data/models/models.dart';
import 'progress_service.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Visible month heading, e.g. `August 2026`.
String formatMonthTitle(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

/// Compact `m:ss`. Negative values keep a leading minus.
String formatClock(num seconds) {
  final value = seconds.round();
  final abs = value.abs();
  final body = '${abs ~/ 60}:${(abs % 60).toString().padLeft(2, '0')}';
  return value < 0 ? '-$body' : body;
}

String _plainNumber(num value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toString();
}

/// Primary metric without a sign: `45 kg`, `0:35`, `36 reps`.
String formatMetricValue(ProgressMetricKind metric, double value) {
  switch (metric) {
    case ProgressMetricKind.weight:
      return '${_plainNumber(value)} kg';
    case ProgressMetricKind.duration:
      return formatClock(value);
    case ProgressMetricKind.setsReps:
      return '${_plainNumber(value)} reps';
  }
}

/// Last minus first. `no change` when the delta is 0.
String formatMetricDelta(ProgressMetricKind metric, double delta) {
  if (delta == 0) return 'no change';
  final body = formatMetricValue(metric, delta.abs());
  return delta > 0 ? '+$body' : '-$body';
}

/// Last value and the month delta, or `No logged sets` when nothing was logged.
String formatTrendSummary(ExerciseMonthTrend row) {
  if (row.lastValue == null) return 'No logged sets';
  final current = formatMetricValue(row.metric, row.lastValue!);
  if (row.firstValue == null || row.sessions.length < 2) return current;
  return '$current  ·  ${formatMetricDelta(row.metric, row.delta)}';
}

String formatSetLine(SetLog set) {
  if (set.durationSeconds != null) {
    return 'Set ${set.setIndex}  ${formatClock(set.durationSeconds!)}';
  }
  if (set.weightKg != null) {
    return 'Set ${set.setIndex}  ${formatMetricValue(ProgressMetricKind.weight, set.weightKg!)} × ${set.reps ?? 0}';
  }
  return 'Set ${set.setIndex}  ${set.reps ?? 0} reps';
}
