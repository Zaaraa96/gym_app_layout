import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/data/models/models.dart';

/// Step 3: v1 JSON maps onto [WorkoutPlan], and invalid files fail with a
/// message that is safe to show in the UI.
void main() {
  const importer = JsonPlanImporter(
    newId: _stableId,
    clock: _clock,
  );

  test('maps the canonical sample onto days, supersets, and common sections',
      () {
    final plan = importer.import(_sampleJson);

    expect(plan.title, 'plan 1');
    expect(plan.source, PlanSource.imported);
    expect(plan.createdAt, DateTime.utc(2026, 8, 26, 12));
    expect(plan.days, hasLength(1));
    expect(plan.commonSections, hasLength(2));

    final day = plan.days.single;
    expect(day.dayId, isNotEmpty);
    expect(day.title, 'day 1- 4sar');
    expect(day.blocks, hasLength(2));

    final superset = day.blocks[0];
    expect(superset.kind, BlockKind.superset);
    expect(superset.svgPath, 'assets/image/exercises/kang-squat.svg');
    expect(superset.exercises.map((e) => e.title),
        ['kang squat', 'leg extension']);
    expect(superset.exercises.first.prescribedSets, 3);
    expect(superset.exercises.first.prescribedReps, 12);
    expect(superset.exercises.first.prescribedDurationSeconds, isNull);
    expect(superset.exercises.first.targetWeightKg, isNull);

    final single = day.blocks[1];
    expect(single.kind, BlockKind.single);
    expect(single.svgPath, 'assets/image/exercises/reverse-lunge-press.svg');
    expect(single.exercises.single.title, 'reverse lunges+ Press');
    expect(single.exercises.single.prescribedReps, 12);

    final abs = plan.commonSections[0];
    expect(abs.title, 'abs');
    expect(abs.blocks.single.kind, BlockKind.single);
    expect(abs.blocks.single.svgPath, 'assets/image/exercises/shoot-out.svg');
    expect(abs.blocks.single.exercises.single.title, 'shoot out');
    expect(abs.blocks.single.exercises.single.prescribedSets, 1);
    expect(abs.blocks.single.exercises.single.prescribedReps, isNull);
    expect(abs.blocks.single.exercises.single.prescribedDurationSeconds, 30);

    expect(plan.commonSections[1].title, 'corrective');
    expect(
      plan.commonSections[1].blocks.single.svgPath,
      'assets/image/exercises/step-lunge-stretch.svg',
    );
  });

  test('ignores the informational days count', () {
    final plan = importer.import(_sampleJson);
    expect(plan.days, hasLength(1));
  });

  test('rejects a trailing comma with a readable error', () {
    expect(
      () => importer.import('{ "name": "plan 1", }'),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('not valid JSON'),
        ),
      ),
    );
  });

  test('rejects a plan with no name', () {
    expect(
      () => importer.import('{"basic-plan":[]}'),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('needs a name'),
        ),
      ),
    );
  });

  test('rejects a plan with no days', () {
    expect(
      () => importer.import('{"name":"empty","basic-plan":[]}'),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('no days'),
        ),
      ),
    );
  });

  test('rejects an unknown block type', () {
    expect(
      () => importer.import('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{ "type": "circuit", "exercise": {} }]
  }]
}
'''),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('single" or "super-set'),
        ),
      ),
    );
  });

  test('rejects a super-set with one movement', () {
    expect(
      () => importer.import('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "super-set",
      "exercise": [
        { "title": "only one", "sets": 3, "times": 10, "duration": null }
      ]
    }]
  }]
}
'''),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('at least two exercises'),
        ),
      ),
    );
  });

  test('rejects an exercise that has both times and duration', () {
    expect(
      () => importer.import('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "plank", "sets": 1, "times": 10, "duration": 30 }
    }]
  }]
}
'''),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('not both'),
        ),
      ),
    );
  });

  test('rejects an exercise with neither times nor duration', () {
    expect(
      () => importer.import('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "plank", "sets": 1, "times": null, "duration": null }
    }]
  }]
}
'''),
      throwsA(
        isA<PlanImportException>().having(
          (e) => e.message,
          'message',
          contains('times (reps) or duration'),
        ),
      ),
    );
  });

  test('common-plan is optional', () {
    final plan = importer.import('''
{
  "name": "solo",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }]
}
''');
    expect(plan.commonSections, isEmpty);
    expect(plan.days.single.blocks.single.exercises.single.title, 'squat');
  });
}

var _ids = 0;

String _stableId() {
  _ids += 1;
  return 'id-$_ids';
}

DateTime _clock() => DateTime.utc(2026, 8, 26, 12);

const _sampleJson = '''
{
  "name": "plan 1",
  "days": 3,
  "basic-plan": [
    {
      "name": "day 1- 4sar",
      "exercises": [
        {
          "type": "super-set",
          "exercise": [
            { "title": "kang squat", "sets": 3, "times": 12, "duration": null },
            { "title": "leg extension", "sets": 3, "times": 12, "duration": null }
          ]
        },
        {
          "type": "single",
          "exercise": {
            "title": "reverse lunges+ Press",
            "sets": 3,
            "times": 12,
            "duration": null
          }
        }
      ]
    }
  ],
  "common-plan": [
    {
      "name": "abs",
      "exercises": [
        {
          "type": "single",
          "exercise": {
            "title": "shoot out",
            "sets": 1,
            "times": null,
            "duration": 30
          }
        }
      ]
    },
    {
      "name": "corrective",
      "exercises": [
        {
          "type": "single",
          "exercise": {
            "title": "step lunge stretch",
            "sets": 3,
            "times": null,
            "duration": 30
          }
        }
      ]
    }
  ]
}
''';
