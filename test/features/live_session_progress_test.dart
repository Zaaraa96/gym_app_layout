import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/workout/live_session_progress.dart';
import 'package:gym_app/features/workout/live_workout_copy.dart';

void main() {
  test('liveSessionProgress counts movements and remaining time', () {
    final now = DateTime.utc(2026, 9, 12);
    final session = WorkoutSession.create(
      planId: 'p',
      planTitleSnapshot: 'Plan',
      dayTitleSnapshot: 'Day',
      planDayId: 'd',
      startedAt: now,
      status: SessionStatus.inProgress,
      exerciseLogs: [
        ExerciseLog.create(
          prescriptionId: 'a',
          blockId: 'b1',
          blockKind: BlockKind.single,
          fromCommonSection: false,
          exerciseTitle: 'squat',
          exerciseTitleKey: 'squat',
          prescribedSets: 2,
          prescribedReps: 10,
          completedAt: now,
          sets: [
            SetLog.create(setIndex: 1, completedAt: now, reps: 10),
            SetLog.create(setIndex: 2, completedAt: now, reps: 10),
          ],
        ),
        ExerciseLog.create(
          prescriptionId: 'b',
          blockId: 'b2',
          blockKind: BlockKind.single,
          fromCommonSection: false,
          exerciseTitle: 'push up',
          exerciseTitleKey: 'push up',
          prescribedSets: 3,
          prescribedReps: 10,
        ),
      ],
    );

    final progress = liveSessionProgress(session);
    expect(progress.currentOrdinal, 2);
    expect(progress.totalMovements, 2);
    expect(progress.line, contains('2 of 2'));
    expect(progress.line, contains('left'));
    expect(progress.remainingSeconds, greaterThan(0));
  });

  test('sessionSavedSummary picks the busiest logged movement', () {
    final now = DateTime.utc(2026, 9, 12);
    final session = WorkoutSession.create(
      planId: 'p',
      planTitleSnapshot: 'Plan',
      dayTitleSnapshot: 'Day',
      planDayId: 'd',
      startedAt: now,
      status: SessionStatus.inProgress,
      exerciseLogs: [
        ExerciseLog.create(
          prescriptionId: 'a',
          blockId: 'b1',
          blockKind: BlockKind.single,
          fromCommonSection: false,
          exerciseTitle: 'Kang squat',
          exerciseTitleKey: 'kang squat',
          prescribedSets: 3,
          prescribedReps: 10,
          sets: [
            SetLog.create(setIndex: 1, completedAt: now, reps: 10),
            SetLog.create(setIndex: 2, completedAt: now, reps: 10),
            SetLog.create(setIndex: 3, completedAt: now, reps: 10),
          ],
        ),
        ExerciseLog.create(
          prescriptionId: 'b',
          blockId: 'b2',
          blockKind: BlockKind.single,
          fromCommonSection: false,
          exerciseTitle: 'push up',
          exerciseTitleKey: 'push up',
          prescribedSets: 2,
          prescribedReps: 10,
          sets: [
            SetLog.create(setIndex: 1, completedAt: now, reps: 8),
          ],
        ),
      ],
    );

    expect(sessionSavedSummary(session), '3 sets of Kang squat saved');
  });

  test('session done beat copy follows the last rating', () {
    expect(LiveWorkoutCopy.sessionDoneBeat(1), contains('easy'));
    expect(LiveWorkoutCopy.sessionDoneBeat(5), contains('Brutal'));
    expect(LiveWorkoutCopy.sessionDoneBeat(null), 'Saved. Session done.');
  });
}
