import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/progress/progress_format.dart';
import 'package:gym_app/features/progress/progress_service.dart';

void main() {
  test('formatMonthTitle names the calendar month', () {
    expect(formatMonthTitle(DateTime.utc(2026, 8)), 'August 2026');
    expect(formatMonthTitle(DateTime.utc(2027, 1, 31)), 'January 2027');
  });

  test('formatClock keeps minutes and a leading minus', () {
    expect(formatClock(0), '0:00');
    expect(formatClock(95), '1:35');
    expect(formatClock(-5), '-0:05');
    expect(formatClock(-75.4), '-1:15');
  });

  test('formatMetricDelta signs weight, duration, and reps', () {
    expect(formatMetricDelta(ProgressMetricKind.weight, 5), '+5 kg');
    expect(formatMetricDelta(ProgressMetricKind.weight, -2.5), '-2.5 kg');
    expect(formatMetricDelta(ProgressMetricKind.weight, 0), 'no change');
    expect(formatMetricDelta(ProgressMetricKind.duration, 15), '+0:15');
    expect(formatMetricDelta(ProgressMetricKind.duration, -75), '-1:15');
    expect(formatMetricDelta(ProgressMetricKind.setsReps, 16), '+16 reps');
    expect(formatMetricValue(ProgressMetricKind.setsReps, 36), '36 reps');
    expect(formatMetricValue(ProgressMetricKind.duration, 95), '1:35');
  });

  test('formatTrendSummary uses last value and the month delta', () {
    final withDelta = ExerciseMonthTrend(
      titleKey: 'kang squat',
      title: 'kang squat',
      metric: ProgressMetricKind.weight,
      firstValue: 40,
      lastValue: 45,
      delta: 5,
      feltEasier: true,
      sessions: [
        SessionExercisePoint(
          sessionId: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          status: SessionStatus.completed,
          completedSets: 1,
          prescribedSets: 3,
          totalReps: 12,
          metPrescription: false,
          primaryValue: 40,
        ),
        SessionExercisePoint(
          sessionId: 2,
          startedAt: DateTime.utc(2026, 8, 20),
          status: SessionStatus.completed,
          completedSets: 1,
          prescribedSets: 3,
          totalReps: 12,
          metPrescription: false,
          primaryValue: 45,
        ),
      ],
    );
    expect(formatTrendSummary(withDelta), '45 kg  ·  +5 kg');

    final once = ExerciseMonthTrend(
      titleKey: 'kang squat',
      title: 'kang squat',
      metric: ProgressMetricKind.weight,
      firstValue: 40,
      lastValue: 40,
      delta: 0,
      feltEasier: false,
      sessions: [
        SessionExercisePoint(
          sessionId: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          status: SessionStatus.completed,
          completedSets: 1,
          prescribedSets: 3,
          totalReps: 12,
          metPrescription: false,
          primaryValue: 40,
        ),
      ],
    );
    expect(formatTrendSummary(once), '40 kg');

    final timed = ExerciseMonthTrend(
      titleKey: 'shoot out',
      title: 'shoot out',
      metric: ProgressMetricKind.duration,
      firstValue: 20,
      lastValue: 35,
      delta: 15,
      feltEasier: false,
      sessions: [
        SessionExercisePoint(
          sessionId: 1,
          startedAt: DateTime.utc(2026, 8, 5),
          status: SessionStatus.completed,
          completedSets: 1,
          prescribedSets: 1,
          totalReps: 0,
          metPrescription: false,
          primaryValue: 20,
        ),
        SessionExercisePoint(
          sessionId: 2,
          startedAt: DateTime.utc(2026, 8, 12),
          status: SessionStatus.completed,
          completedSets: 1,
          prescribedSets: 1,
          totalReps: 0,
          metPrescription: true,
          primaryValue: 35,
        ),
      ],
    );
    expect(formatTrendSummary(timed), '0:35  ·  +0:15');

    final empty = ExerciseMonthTrend(
      titleKey: 'kang squat',
      title: 'kang squat',
      metric: ProgressMetricKind.weight,
      delta: 0,
      feltEasier: false,
      sessions: [],
    );
    expect(formatTrendSummary(empty), 'No logged sets');
  });

  test('formatTrendSummary omits the delta when only one session has a value',
      () {
    final one = ExerciseMonthTrend(
      titleKey: 'squat',
      title: 'squat',
      metric: ProgressMetricKind.weight,
      firstValue: 40,
      lastValue: 40,
      delta: 0,
      feltEasier: false,
      sessions: [
        SessionExercisePoint(
          sessionId: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          status: SessionStatus.completed,
          completedSets: 1,
          prescribedSets: 3,
          totalReps: 12,
          metPrescription: false,
          primaryValue: 40,
        ),
      ],
    );
    expect(formatTrendSummary(one), '40 kg');
  });

  test('formatClock keeps minutes and a leading minus', () {
    expect(formatClock(0), '0:00');
    expect(formatClock(75), '1:15');
    expect(formatClock(-5), '-0:05');
  });

  test('formatSetLine covers weight, bodyweight, and duration', () {
    expect(
      formatSetLine(
        SetLog.create(
          setIndex: 1,
          completedAt: DateTime.utc(2026, 8, 1),
          reps: 12,
          weightKg: 40,
        ),
      ),
      'Set 1  40 kg × 12',
    );
    expect(
      formatSetLine(
        SetLog.create(
          setIndex: 2,
          completedAt: DateTime.utc(2026, 8, 1),
          reps: 10,
        ),
      ),
      'Set 2  10 reps',
    );
    expect(
      formatSetLine(
        SetLog.create(
          setIndex: 3,
          completedAt: DateTime.utc(2026, 8, 1),
          reps: 8,
          weightKg: 0,
        ),
      ),
      'Set 3  0 kg × 8',
    );
    expect(
      formatSetLine(
        SetLog.create(
          setIndex: 1,
          completedAt: DateTime.utc(2026, 8, 1),
          durationSeconds: 35,
        ),
      ),
      'Set 1  0:35',
    );
  });
}
