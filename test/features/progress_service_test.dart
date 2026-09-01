import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_session_repository.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/progress/progress_service.dart';

/// Step 4: [ProgressService] folds a month of sessions using the Step 2 rules.
void main() {
  const service = ProgressService();

  test('exerciseTitleKeyFor trims and lowercases without rewriting punctuation',
      () {
    expect(exerciseTitleKeyFor('  Kang Squat '), 'kang squat');
    expect(exerciseTitleKeyFor('Push-up'), 'push-up');
    expect(exerciseTitleKeyFor('Push up'), 'push up');
  });

  test('an empty month has no dots and no exercise rows', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: const [],
    );
    expect(progress.isEmpty, isTrue);
    expect(progress.daysWithWorkouts, isEmpty);
    expect(progress.exercises, isEmpty);
  });

  test('abandoned sessions and other months are ignored', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 7, 31),
          status: SessionStatus.completed,
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 40)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 10),
          status: SessionStatus.abandoned,
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 50)
          ],
        ),
      ],
    );
    expect(progress.isEmpty, isTrue);
  });

  test('weight is the primary metric when any set has a load', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2, 9),
          logs: [
            _repLog(
                title: 'Kang Squat', reps: [12, 10], weight: 40, difficulty: 4),
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 20, 9),
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 45, difficulty: 3),
          ],
        ),
      ],
    );

    expect(progress.daysWithWorkouts, [
      DateTime.utc(2026, 8, 2),
      DateTime.utc(2026, 8, 20),
    ]);
    final row = progress.exercises.single;
    expect(row.titleKey, 'kang squat');
    expect(row.title, 'kang squat');
    expect(row.metric, ProgressMetricKind.weight);
    expect(row.firstValue, 40);
    expect(row.lastValue, 45);
    expect(row.delta, 5);
    expect(row.feltEasier, isTrue);
    expect(row.sessions.first.completedSets, 2);
    expect(row.sessions.last.completedSets, 1);
  });

  test('felt easier is false when the load got worse', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 50, difficulty: 4)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 20),
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 40, difficulty: 2)
          ],
        ),
      ],
    );
    expect(progress.exercises.single.feltEasier, isFalse);
    expect(progress.exercises.single.delta, -10);
  });

  test('duration uses the longest timed set and flags meeting the prescription',
      () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 5),
          logs: [
            _durationLog(seconds: [20], prescribed: 30, difficulty: 4)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 12),
          logs: [
            _durationLog(seconds: [30, 35], prescribed: 30, difficulty: 3)
          ],
        ),
      ],
    );
    final row = progress.exercises.single;
    expect(row.metric, ProgressMetricKind.duration);
    expect(row.firstValue, 20);
    expect(row.lastValue, 35);
    expect(row.delta, 15);
    expect(row.sessions.first.metPrescription, isFalse);
    expect(row.sessions.last.metPrescription, isTrue);
    expect(row.feltEasier, isTrue);
  });

  test('sets and reps are the fallback when there is no weight or duration',
      () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 5),
          logs: [
            _repLog(title: 'push up', reps: [10, 10], prescribedSets: 3)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 12),
          logs: [
            _repLog(title: 'push up', reps: [12, 12, 12], prescribedSets: 3)
          ],
        ),
      ],
    );
    final row = progress.exercises.single;
    expect(row.metric, ProgressMetricKind.setsReps);
    expect(row.firstValue, 20);
    expect(row.lastValue, 36);
    expect(row.delta, 16);
    expect(row.sessions.first.completedSets, 2);
    expect(row.sessions.last.completedSets, 3);
    expect(row.sessions.last.prescribedSets, 3);
  });

  test(
      'same titleKey across days rolls up and in-progress sessions still count',
      () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 1, 18),
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 40)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 1, 7),
          status: SessionStatus.inProgress,
          logs: [
            _repLog(title: 'Kang Squat', reps: [8], weight: 35)
          ],
        ),
      ],
    );
    expect(progress.daysWithWorkouts, [DateTime.utc(2026, 8, 1)]);
    expect(progress.exercises, hasLength(1));
    expect(progress.exercises.single.sessions, hasLength(2));
    expect(progress.exercises.single.sessions.first.sessionId, '2');
    expect(progress.exercises.single.firstValue, 35);
    expect(progress.exercises.single.lastValue, 40);
  });

  test('the heaviest set wins, not the last one', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 10),
          logs: [
            ExerciseLog.create(
              prescriptionId: 'p-squat',
              blockId: 'block-squat',
              blockKind: BlockKind.single,
              fromCommonSection: false,
              exerciseTitle: 'squat',
              exerciseTitleKey: 'squat',
              prescribedSets: 3,
              prescribedReps: 5,
              sets: [
                SetLog.create(
                  setIndex: 1,
                  completedAt: DateTime.utc(2026, 8, 10),
                  reps: 5,
                  weightKg: 50,
                ),
                SetLog.create(
                  setIndex: 2,
                  completedAt: DateTime.utc(2026, 8, 10),
                  reps: 5,
                  weightKg: 40,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(progress.exercises.single.metric, ProgressMetricKind.weight);
    expect(progress.exercises.single.lastValue, 50);
  });

  test('same title in one session rolls up, and weight beats duration', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 10),
          logs: [
            _repLog(
              title: 'plank',
              reps: [1],
              weight: 10,
              prescribedSets: 1,
            ),
            ExerciseLog.create(
              prescriptionId: 'p-plank-hold',
              blockId: 'block-hold',
              blockKind: BlockKind.single,
              fromCommonSection: true,
              exerciseTitle: 'Plank',
              exerciseTitleKey: 'plank',
              prescribedSets: 1,
              prescribedDurationSeconds: 30,
              sets: [
                SetLog.create(
                  setIndex: 1,
                  completedAt: DateTime.utc(2026, 8, 10),
                  durationSeconds: 45,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final row = progress.exercises.single;
    expect(row.metric, ProgressMetricKind.weight);
    expect(row.lastValue, 10);
    expect(row.sessions.single.completedSets, 2);
    expect(row.sessions.single.prescribedSets, 2);
  });

  test('weight beats duration and the heaviest set wins, not the last', () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 5),
          logs: [
            ExerciseLog.create(
              prescriptionId: 'p-plank',
              blockId: 'block-abs',
              blockKind: BlockKind.single,
              fromCommonSection: true,
              exerciseTitle: 'plank',
              exerciseTitleKey: 'plank',
              prescribedSets: 1,
              prescribedDurationSeconds: 30,
              difficulty: 4,
              completedAt: DateTime.utc(2026, 8, 5),
              sets: [
                SetLog.create(
                  setIndex: 1,
                  completedAt: DateTime.utc(2026, 8, 5),
                  durationSeconds: 30,
                  weightKg: 40,
                ),
                SetLog.create(
                  setIndex: 2,
                  completedAt: DateTime.utc(2026, 8, 5),
                  durationSeconds: 45,
                  weightKg: 35,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final row = progress.exercises.single;
    expect(row.metric, ProgressMetricKind.weight);
    expect(row.firstValue, 40);
    expect(row.lastValue, 40);
    expect(row.sessions.single.metPrescription, isTrue);
    expect(row.sessions.single.totalReps, 0);
  });

  test('felt easier needs two rated sessions and the same or better load', () {
    final sameLoadEasier = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          logs: [_repLog(title: 'kang squat', reps: [12], weight: 40, difficulty: 5)],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 20),
          logs: [_repLog(title: 'kang squat', reps: [12], weight: 40, difficulty: 3)],
        ),
      ],
    );
    expect(sameLoadEasier.exercises.single.feltEasier, isTrue);
    expect(sameLoadEasier.exercises.single.delta, 0);

    final missingDifficulty = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          logs: [_repLog(title: 'kang squat', reps: [12], weight: 40, difficulty: 4)],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 20),
          logs: [_repLog(title: 'kang squat', reps: [12], weight: 50)],
        ),
      ],
    );
    expect(missingDifficulty.exercises.single.feltEasier, isFalse);

    final oneSession = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          logs: [_repLog(title: 'kang squat', reps: [12], weight: 40, difficulty: 2)],
        ),
      ],
    );
    expect(oneSession.exercises.single.feltEasier, isFalse);

    final gotHarder = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          logs: [
            _repLog(
                title: 'kang squat', reps: [12], weight: 40, difficulty: 2)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 20),
          logs: [
            _repLog(
                title: 'kang squat', reps: [12], weight: 45, difficulty: 4)
          ],
        ),
      ],
    );
    expect(gotHarder.exercises.single.feltEasier, isFalse);
    expect(gotHarder.exercises.single.delta, 5);
  });

  test('felt easier is false when load improved but difficulty did not drop',
      () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 2),
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 40, difficulty: 3)
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 20),
          logs: [
            _repLog(title: 'kang squat', reps: [12], weight: 50, difficulty: 3)
          ],
        ),
      ],
    );
    expect(progress.exercises.single.delta, 10);
    expect(progress.exercises.single.feltEasier, isFalse);
  });

  test('in-progress sessions still count as a workout day and a trend point',
      () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 15, 10),
          status: SessionStatus.inProgress,
          logs: [
            _repLog(title: 'kang squat', reps: [10], weight: 40),
          ],
        ),
      ],
    );
    expect(progress.daysWithWorkouts, [DateTime.utc(2026, 8, 15)]);
    expect(progress.exercises.single.title, 'kang squat');
    expect(progress.exercises.single.lastValue, 40);
    expect(progress.exercises.single.sessions.single.status,
        SessionStatus.inProgress);
    expect(progress.isEmpty, isFalse);
  });

  test('first-seen exercise order, last title, and empty duration sets stay null',
      () {
    final progress = service.fold(
      month: DateTime.utc(2026, 8),
      sessions: [
        _session(
          id: 1,
          startedAt: DateTime.utc(2026, 8, 5),
          logs: [
            _repLog(title: 'Push Up', reps: [10]),
            _durationLog(seconds: const [], prescribed: 30),
          ],
        ),
        _session(
          id: 2,
          startedAt: DateTime.utc(2026, 8, 12),
          logs: [
            ExerciseLog.create(
              prescriptionId: 'p-shoot',
              blockId: 'block-abs',
              blockKind: BlockKind.single,
              fromCommonSection: true,
              exerciseTitle: 'Shoot Out',
              exerciseTitleKey: 'shoot out',
              prescribedSets: 1,
              prescribedDurationSeconds: 30,
              sets: [
                SetLog.create(
                  setIndex: 1,
                  completedAt: DateTime.utc(2026, 8, 12),
                  durationSeconds: 40,
                ),
              ],
            ),
            _repLog(title: 'push up', reps: [12]),
          ],
        ),
      ],
    );

    expect(
      progress.exercises.map((row) => row.titleKey),
      ['push up', 'shoot out'],
    );
    expect(progress.exercises.first.title, 'push up');
    expect(progress.exercises.last.title, 'Shoot Out');
    expect(progress.exercises.last.metric, ProgressMetricKind.duration);
    expect(progress.exercises.last.firstValue, 40);
    expect(progress.exercises.last.lastValue, 40);
    expect(progress.exercises.last.sessions.first.primaryValue, isNull);
    expect(progress.exercises.last.sessions.first.completedSets, 0);
  });

  test('loadMonth reads sessions from the repository then folds', () async {
    final sessions = MemorySessionRepository();
    await sessions.save(
      _session(
        id: 1,
        startedAt: DateTime.utc(2026, 8, 2, 9),
        logs: [
          _repLog(
            title: 'Kang Squat',
            reps: [12],
            weight: 40,
            difficulty: 4,
          ),
        ],
      ),
    );
    await sessions.save(
      _session(
        id: 2,
        startedAt: DateTime.utc(2026, 8, 20, 9),
        logs: [
          _repLog(title: 'kang squat', reps: [12], weight: 45, difficulty: 3),
        ],
      ),
    );

    final progress = await service.loadMonth(
      sessions: sessions,
      month: DateTime.utc(2026, 8),
    );
    expect(progress.daysWithWorkouts, [
      DateTime.utc(2026, 8, 2),
      DateTime.utc(2026, 8, 20),
    ]);
    expect(progress.exercises.single.feltEasier, isTrue);
    expect(progress.exercises.single.delta, 5);
  });
}

WorkoutSession _session({
  required int id,
  required DateTime startedAt,
  required List<ExerciseLog> logs,
  SessionStatus status = SessionStatus.completed,
}) {
  final session = WorkoutSession.create(
    uuid: '$id',
    planId: '1',
    planDayId: 'day-1',
    planTitleSnapshot: 'plan 1',
    dayTitleSnapshot: 'day 1',
    startedAt: startedAt,
    status: status,
    endedAt: status == SessionStatus.inProgress ? null : startedAt,
    exerciseLogs: logs,
  );
  session.id = id;
  return session;
}

ExerciseLog _repLog({
  required String title,
  required List<int> reps,
  double? weight,
  int prescribedSets = 3,
  int? difficulty,
}) {
  final started = DateTime.utc(2026, 8, 1);
  return ExerciseLog.create(
    prescriptionId: 'p-$title',
    blockId: 'block-$title',
    blockKind: BlockKind.single,
    fromCommonSection: false,
    exerciseTitle: title,
    exerciseTitleKey: exerciseTitleKeyFor(title),
    prescribedSets: prescribedSets,
    prescribedReps: 12,
    difficulty: difficulty,
    completedAt: difficulty == null ? null : started,
    sets: [
      for (var i = 0; i < reps.length; i++)
        SetLog.create(
          setIndex: i + 1,
          completedAt: started,
          reps: reps[i],
          weightKg: weight,
        ),
    ],
  );
}

ExerciseLog _durationLog({
  required List<int> seconds,
  required int prescribed,
  int? difficulty,
}) {
  final started = DateTime.utc(2026, 8, 1);
  return ExerciseLog.create(
    prescriptionId: 'p-shoot',
    blockId: 'block-abs',
    blockKind: BlockKind.single,
    fromCommonSection: true,
    exerciseTitle: 'shoot out',
    exerciseTitleKey: 'shoot out',
    prescribedSets: 1,
    prescribedDurationSeconds: prescribed,
    difficulty: difficulty,
    completedAt: difficulty == null ? null : started,
    sets: [
      for (var i = 0; i < seconds.length; i++)
        SetLog.create(
          setIndex: i + 1,
          completedAt: started,
          durationSeconds: seconds[i],
        ),
    ],
  );
}
