import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/day_card_summary.dart';

ExercisePrescription _ex({
  required String id,
  required String title,
  int sets = 3,
  int? reps,
  int? duration,
  List<String> targets = const [],
}) {
  return ExercisePrescription.create(
    prescriptionId: id,
    title: title,
    prescribedSets: sets,
    prescribedReps: reps,
    prescribedDurationSeconds: duration,
    targetAreaIds: targets,
  );
}

PlanDay _day({
  String title = 'Day 1',
  String summary = '',
  List<ExerciseBlock> blocks = const [],
}) {
  return PlanDay.create(dayId: 'd1', title: title, summary: summary, blocks: blocks);
}

ExerciseBlock _single(ExercisePrescription exercise) {
  return ExerciseBlock.create(
    blockId: exercise.prescriptionId,
    kind: BlockKind.single,
    exercises: [exercise],
  );
}

void main() {
  test('custom unmatched exercises have no chips and no thumbnails', () {
    final day = _day(
      blocks: [
        _single(_ex(id: 'p1', title: 'mystery move', reps: 12)),
      ],
    );
    expect(dayCardTargetAreaIds(day), isEmpty);
    expect(dayCardThumbnails(day), isEmpty);
    expect(dayFocusLabel(day), isNull);
    expect(dayVolumeLabel(day), '1 exercise · 3 sets');
  });

  test('catalog titles fill chips and stills when nothing is stored', () {
    final day = _day(
      blocks: [
        _single(_ex(id: 'p1', title: 'plank', sets: 3, duration: 30)),
      ],
    );
    expect(dayCardTargetAreaIds(day), ['abs', 'core']);
    expect(dayFocusLabel(day), 'Core');
    expect(dayCardThumbnails(day).single.uri, 'assets/image/exercises/plank.png');
    expect(dayVolumeLabel(day), '1 exercise · 3 sets');
  });

  test('stored target areas win over catalog defaults', () {
    final day = _day(
      blocks: [
        _single(
          _ex(
            id: 'p1',
            title: 'plank',
            duration: 30,
            targets: ['glutes'],
          ),
        ),
      ],
    );
    expect(dayCardTargetAreaIds(day), ['glutes']);
    expect(dayFocusLabel(day), 'Legs');
  });

  test('summary overrides derived focus; a named title skips the cluster', () {
    expect(
      dayFocusLabel(
        _day(
          title: 'Day 1',
          summary: 'upper body notes',
          blocks: [_single(_ex(id: 'p1', title: 'plank', duration: 30))],
        ),
      ),
      'upper body notes',
    );
    expect(
      dayFocusLabel(
        _day(
          title: 'Day 1 — Squat and push',
          blocks: [_single(_ex(id: 'p1', title: 'plank', duration: 30))],
        ),
      ),
      isNull,
    );
  });

  test('focusFromTargetAreas clusters push pull legs core and mixed', () {
    expect(focusFromTargetAreas(['abs', 'core']), 'Core');
    expect(
      focusFromTargetAreas(['chest', 'triceps', 'front-shoulders']),
      'Push',
    );
    expect(focusFromTargetAreas(['lats', 'biceps']), 'Pull');
    expect(focusFromTargetAreas(['quads', 'glutes']), 'Legs');
    expect(focusFromTargetAreas(['chest', 'quads']), 'Push · Legs');
    expect(focusFromTargetAreas(['chest', 'quads', 'abs']), 'Mixed');
    expect(focusFromTargetAreas(['full-body']), 'Full body');
    expect(focusFromTargetAreas(const []), isNull);
  });

  test('visible chips cap at three and report overflow', () {
    final day = _day(
      blocks: [
        _single(
          _ex(
            id: 'p1',
            title: 'custom',
            reps: 8,
            targets: ['chest', 'triceps', 'front-shoulders', 'abs', 'core'],
          ),
        ),
      ],
    );
    expect(dayCardVisibleTargetAreaIds(day), [
      'chest',
      'triceps',
      'front-shoulders',
    ]);
    expect(dayCardHiddenTargetAreaCount(day), 2);
  });

  test('estimated duration includes assumed rest and rounds to ~5 min', () {
    final plank = _day(
      blocks: [
        _single(_ex(id: 'p1', title: 'plank', sets: 3, duration: 30)),
      ],
    );
    // 90s work + 120s rest = 210s → 4 min → ~5 min
    expect(estimatedDaySeconds(plank), 210);
    expect(dayEstimateLabel(plank), '~5 min');
    expect(dayEstimateLabel(_day()), isEmpty);
  });

  test('volume counts superset partners as separate exercises', () {
    final day = _day(
      blocks: [
        ExerciseBlock.create(
          blockId: 'ss',
          kind: BlockKind.superset,
          exercises: [
            _ex(id: 'a', title: 'kang squat', reps: 12),
            _ex(id: 'b', title: 'leg extension', reps: 10),
          ],
        ),
        _single(_ex(id: 'c', title: 'plank', sets: 1, duration: 30)),
      ],
    );
    expect(dayMovementCount(day), 3);
    expect(dayVolumeLabel(day), '3 exercises');
    expect(
      dayCardThumbnails(day).map((m) => m.uri),
      [
        'assets/image/exercises/kang-squat.png',
        'assets/image/exercises/leg-extension.png',
        'assets/image/exercises/plank.png',
      ],
    );
  });

  test('duplicate catalog stills appear once', () {
    final day = _day(
      blocks: [
        _single(_ex(id: 'a', title: 'plank', duration: 20)),
        _single(_ex(id: 'b', title: 'plank', duration: 30)),
      ],
    );
    expect(dayCardThumbnails(day), hasLength(1));
  });
}
