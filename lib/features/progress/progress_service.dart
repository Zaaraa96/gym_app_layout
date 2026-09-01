import '../../data/models/models.dart';
import '../../data/session_repository.dart';

/// How the month view measures an exercise group (Step 2 primary metric).
enum ProgressMetricKind { weight, duration, setsReps }

/// One session's contribution to an exercise's month trend.
class SessionExercisePoint {
  const SessionExercisePoint({
    required this.sessionId,
    required this.startedAt,
    required this.status,
    required this.completedSets,
    required this.prescribedSets,
    required this.totalReps,
    required this.metPrescription,
    this.primaryValue,
    this.difficulty,
  });

  /// [WorkoutSession.uuid], not a local row key.
  final String sessionId;
  final DateTime startedAt;
  final SessionStatus status;

  /// Max weight, max duration, or total reps — depending on the group metric.
  final double? primaryValue;
  final int completedSets;
  final int prescribedSets;
  final int totalReps;
  final int? difficulty;

  /// Duration work: any set lasted at least the prescribed seconds.
  final bool metPrescription;
}

/// One [exerciseTitleKey] rolled up across a month of sessions.
class ExerciseMonthTrend {
  const ExerciseMonthTrend({
    required this.titleKey,
    required this.title,
    required this.metric,
    required this.delta,
    required this.feltEasier,
    required this.sessions,
    this.firstValue,
    this.lastValue,
  });

  final String titleKey;
  final String title;
  final ProgressMetricKind metric;
  final double? firstValue;
  final double? lastValue;

  /// Last session's primary value minus the first. Up is better.
  final double delta;
  final bool feltEasier;
  final List<SessionExercisePoint> sessions;
}

/// Calendar + per-exercise numbers for one visible month.
class MonthProgress {
  const MonthProgress({
    required this.monthStart,
    required this.exercises,
    required this.daysWithWorkouts,
  });

  final DateTime monthStart;
  final List<ExerciseMonthTrend> exercises;

  /// UTC midnight dates that have a non-abandoned session.
  final List<DateTime> daysWithWorkouts;

  bool get isEmpty => exercises.isEmpty && daysWithWorkouts.isEmpty;
}

/// Pure fold of the Step 2 month rules. Does not touch Isar.
class ProgressService {
  const ProgressService();

  MonthProgress fold({
    required DateTime month,
    required List<WorkoutSession> sessions,
  }) {
    final monthStart = DateTime.utc(month.year, month.month);
    final monthEnd = DateTime.utc(month.year, month.month + 1);

    final inMonth = sessions.where((session) {
      final started = session.startedAt.toUtc();
      return !started.isBefore(monthStart) &&
          started.isBefore(monthEnd) &&
          session.status != SessionStatus.abandoned;
    }).toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final days = <DateTime>{};
    for (final session in inMonth) {
      days.add(_dateOnly(session.startedAt));
    }

    final order = <String>[];
    final grouped = <String, List<ExerciseLog>>{};
    for (final session in inMonth) {
      for (final log in session.exerciseLogs) {
        if (!grouped.containsKey(log.exerciseTitleKey)) {
          order.add(log.exerciseTitleKey);
          grouped[log.exerciseTitleKey] = [];
        }
        grouped[log.exerciseTitleKey]!.add(log);
      }
    }

    final exercises = <ExerciseMonthTrend>[];
    for (final key in order) {
      exercises.add(_trendFor(key, grouped[key]!, inMonth));
    }

    final dayList = days.toList()..sort();
    return MonthProgress(
      monthStart: monthStart,
      exercises: exercises,
      daysWithWorkouts: dayList,
    );
  }

  ExerciseMonthTrend _trendFor(
    String key,
    List<ExerciseLog> allLogs,
    List<WorkoutSession> sessions,
  ) {
    final metric = _metricFor(allLogs);
    final points = <SessionExercisePoint>[];
    var title = allLogs.last.exerciseTitle;

    for (final session in sessions) {
      final logs = [
        for (final log in session.exerciseLogs)
          if (log.exerciseTitleKey == key) log,
      ];
      if (logs.isEmpty) continue;
      title = logs.last.exerciseTitle;
      points.add(_point(session, logs, metric));
    }

    final valued = [
      for (final point in points)
        if (point.primaryValue != null) point,
    ];
    final firstValue = valued.isEmpty ? null : valued.first.primaryValue;
    final lastValue = valued.isEmpty ? null : valued.last.primaryValue;
    final delta =
        firstValue == null || lastValue == null ? 0.0 : lastValue - firstValue;

    return ExerciseMonthTrend(
      titleKey: key,
      title: title,
      metric: metric,
      firstValue: firstValue,
      lastValue: lastValue,
      delta: delta,
      feltEasier: _feltEasier(points),
      sessions: points,
    );
  }

  SessionExercisePoint _point(
    WorkoutSession session,
    List<ExerciseLog> logs,
    ProgressMetricKind metric,
  ) {
    var completedSets = 0;
    var prescribedSets = 0;
    var totalReps = 0;
    var metPrescription = false;
    int? difficulty;

    for (final log in logs) {
      completedSets += log.sets.length;
      prescribedSets += log.prescribedSets;
      for (final set in log.sets) {
        totalReps += set.reps ?? 0;
        final prescribed = log.prescribedDurationSeconds;
        if (prescribed != null &&
            set.durationSeconds != null &&
            set.durationSeconds! >= prescribed) {
          metPrescription = true;
        }
      }
      if (log.difficulty != null) difficulty = log.difficulty;
    }

    return SessionExercisePoint(
      sessionId: session.uuid,
      startedAt: session.startedAt,
      status: session.status,
      primaryValue: _primaryValue(logs, metric),
      completedSets: completedSets,
      prescribedSets: prescribedSets,
      totalReps: totalReps,
      difficulty: difficulty,
      metPrescription: metPrescription,
    );
  }

  ProgressMetricKind _metricFor(List<ExerciseLog> logs) {
    for (final log in logs) {
      for (final set in log.sets) {
        if (set.weightKg != null) return ProgressMetricKind.weight;
      }
    }
    for (final log in logs) {
      if (log.prescribedDurationSeconds != null) {
        return ProgressMetricKind.duration;
      }
    }
    return ProgressMetricKind.setsReps;
  }

  double? _primaryValue(List<ExerciseLog> logs, ProgressMetricKind metric) {
    switch (metric) {
      case ProgressMetricKind.weight:
        return _maxWeight(logs);
      case ProgressMetricKind.duration:
        return _maxDuration(logs);
      case ProgressMetricKind.setsReps:
        var reps = 0;
        for (final log in logs) {
          for (final set in log.sets) {
            reps += set.reps ?? 0;
          }
        }
        return reps.toDouble();
    }
  }

  double? _maxWeight(List<ExerciseLog> logs) {
    double? max;
    for (final log in logs) {
      for (final set in log.sets) {
        final weight = set.weightKg;
        if (weight == null) continue;
        max = max == null || weight > max ? weight : max;
      }
    }
    return max;
  }

  double? _maxDuration(List<ExerciseLog> logs) {
    double? max;
    for (final log in logs) {
      for (final set in log.sets) {
        final seconds = set.durationSeconds;
        if (seconds == null) continue;
        final value = seconds.toDouble();
        max = max == null || value > max ? value : max;
      }
    }
    return max;
  }

  /// Load the month from [sessions], then fold. Pages call this once.
  Future<MonthProgress> loadMonth({
    required SessionRepository sessions,
    required DateTime month,
  }) async {
    return fold(month: month, sessions: await sessions.forMonth(month));
  }

  bool _feltEasier(List<SessionExercisePoint> points) {
    if (points.length < 2) return false;
    final first = points.first;
    final last = points.last;
    if (first.primaryValue == null || last.primaryValue == null) return false;
    if (first.difficulty == null || last.difficulty == null) return false;
    final loadSameOrBetter = last.primaryValue! >= first.primaryValue!;
    return loadSameOrBetter && last.difficulty! < first.difficulty!;
  }

  DateTime _dateOnly(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
