import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/common_section_migration.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/plan_validation.dart';

void main() {
  group('required plan validation', () {
    test('empty name blocks activation', () {
      final plan = _plan(title: '', days: [_day(blocks: [_single()])]);
      final issues = requiredIssuesFor(plan);
      expect(issues.single.stepKey, detailsStepKey);
      expect(issues.single.message, 'Add a plan name.');
      expect(planCanActivate(plan), isFalse);
    });

    test('a plan with no days is invalid', () {
      final plan = _plan(days: const []);
      expect(requiredIssuesFor(plan).single.message, 'Add at least one day.');
    });

    test('every day needs a name and at least one exercise', () {
      final plan = _plan(
        days: [
          _day(title: '', blocks: const []),
        ],
      );
      final messages = requiredIssuesFor(plan).map((issue) => issue.message);
      expect(messages, contains('Add a name for this day.'));
      expect(messages, contains('Add at least one exercise.'));
    });

    test('single blocks need exactly one exercise', () {
      final plan = _plan(
        days: [
          _day(
            blocks: [
              ExerciseBlock.create(
                blockId: 'b',
                kind: BlockKind.single,
                exercises: [_exercise(), _exercise(title: 'row')],
              ),
            ],
          ),
        ],
      );
      expect(
        requiredIssuesFor(plan).single.message,
        contains('exactly one exercise'),
      );
    });

    test('supersets need at least two exercises', () {
      final plan = _plan(
        days: [
          _day(
            blocks: [
              ExerciseBlock.create(
                blockId: 'b',
                kind: BlockKind.superset,
                exercises: [_exercise()],
              ),
            ],
          ),
        ],
      );
      expect(
        requiredIssuesFor(plan).single.message,
        contains('at least two exercises'),
      );
    });

    test('every exercise needs a name, sets, and reps or duration', () {
      final nameless = _plan(
        days: [
          _day(
            blocks: [
              ExerciseBlock.create(
                blockId: 'b',
                kind: BlockKind.single,
                exercises: [_exercise(title: '')],
              ),
            ],
          ),
        ],
      );
      expect(
        requiredIssuesFor(nameless).any((issue) => issue.message.contains('name')),
        isTrue,
      );

      final noLoad = _plan(
        days: [
          _day(
            blocks: [
              ExerciseBlock.create(
                blockId: 'b',
                kind: BlockKind.single,
                exercises: [
                  ExercisePrescription.create(
                    prescriptionId: 'p',
                    title: 'squat',
                    prescribedSets: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final messages = requiredIssuesFor(noLoad).map((issue) => issue.message);
      expect(messages, contains('"squat" needs at least 1 set.'));
      expect(
        messages,
        contains('"squat" needs reps or duration greater than zero.'),
      );
    });

    test('a complete plan can activate', () {
      final plan = _plan(days: [_day(blocks: [_single()])]);
      expect(requiredIssuesFor(plan), isEmpty);
      expect(planCanActivate(plan), isTrue);
    });
  });

  group('step visuals', () {
    test('details, day, and review use four distinct states', () {
      final plan = _plan(
        title: 'Push',
        days: [
          _day(title: 'Day 1', blocks: [_single()]),
          _day(title: 'Upper', blocks: const []),
        ],
      );
      final steps = builderStepsFor(plan);
      expect(steps.map((step) => step.kind).toList(), [
        BuilderStepKind.details,
        BuilderStepKind.day,
        BuilderStepKind.day,
        BuilderStepKind.review,
      ]);
      expect(
        visualForStep(
          step: steps[0],
          plan: plan,
          currentIndex: 1,
          stepIndex: 0,
        ),
        BuilderStepVisual.complete,
      );
      expect(
        visualForStep(
          step: steps[1],
          plan: plan,
          currentIndex: 1,
          stepIndex: 1,
        ),
        BuilderStepVisual.current,
      );
      expect(
        visualForStep(
          step: steps[2],
          plan: plan,
          currentIndex: 1,
          stepIndex: 2,
        ),
        BuilderStepVisual.incomplete,
      );
      expect(
        visualForStep(
          step: steps[3],
          plan: plan,
          currentIndex: 1,
          stepIndex: 3,
        ),
        BuilderStepVisual.untouched,
      );
    });
  });

  group('common-section migration', () {
    test('converts sections into days and suffixes colliding titles', () {
      final days = migrateCommonSectionsToDays(
        days: [_day(title: 'abs', blocks: [_single()])],
        sections: [
          CommonSection.create(
            sectionId: 'sec-abs',
            title: 'abs',
            blocks: [
              ExerciseBlock.create(
                blockId: 'block-abs',
                kind: BlockKind.single,
                exercises: [_exercise(title: 'plank')],
              ),
            ],
          ),
        ],
      );
      expect(days.map((day) => day.title), ['abs', 'abs (extras)']);
      expect(days.last.dayId, 'sec-abs');
      expect(days.last.blocks.single.exercises.single.title, 'plank');
    });
  });
}

WorkoutPlan _plan({
  String title = 'Push',
  List<PlanDay>? days,
}) {
  final now = DateTime.utc(2026, 9, 7);
  return WorkoutPlan.create(
    title: title,
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: days ?? [_day(blocks: [_single()])],
  );
}

PlanDay _day({
  String title = 'Day 1',
  List<ExerciseBlock> blocks = const [],
}) {
  return PlanDay.create(dayId: 'day-$title', title: title, blocks: blocks);
}

ExerciseBlock _single() => ExerciseBlock.create(
      blockId: 'block-1',
      kind: BlockKind.single,
      exercises: [_exercise()],
    );

ExercisePrescription _exercise({String title = 'squat'}) {
  return ExercisePrescription.create(
    prescriptionId: 'p-$title',
    title: title,
    prescribedSets: 3,
    prescribedReps: 10,
  );
}
