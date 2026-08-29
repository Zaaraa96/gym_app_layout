import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/progress/progress_format.dart';
import 'package:gym_app/features/progress/progress_service.dart';

void main() {
  test('formatMonthTitle names the calendar month', () {
    expect(formatMonthTitle(DateTime.utc(2026, 8)), 'August 2026');
    expect(formatMonthTitle(DateTime.utc(2027, 1, 31)), 'January 2027');
  });

  test('formatMetricDelta signs weight, duration, and reps', () {
    expect(formatMetricDelta(ProgressMetricKind.weight, 5), '+5 kg');
    expect(formatMetricDelta(ProgressMetricKind.weight, -2.5), '-2.5 kg');
    expect(formatMetricDelta(ProgressMetricKind.weight, 0), 'no change');
    expect(formatMetricDelta(ProgressMetricKind.duration, 15), '+0:15');
    expect(formatMetricDelta(ProgressMetricKind.setsReps, 16), '+16 reps');
  });

  test('formatTrendSummary uses last value and the month delta', () {
    const withDelta = ExerciseMonthTrend(
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

    const empty = ExerciseMonthTrend(
      titleKey: 'kang squat',
      title: 'kang squat',
      metric: ProgressMetricKind.weight,
      delta: 0,
      feltEasier: false,
      sessions: [],
    );
    expect(formatTrendSummary(empty), 'No logged sets');
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
          setIndex: 1,
          completedAt: DateTime.utc(2026, 8, 1),
          durationSeconds: 35,
        ),
      ),
      'Set 1  0:35',
    );
  });
}
