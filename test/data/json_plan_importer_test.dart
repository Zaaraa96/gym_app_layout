import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/domain/models/models.dart';

/// Step 3: v1 JSON maps onto [WorkoutPlan], and invalid files fail with a
/// message that is safe to show in the UI.
void main() {
  const importer = JsonPlanImporter(
    newId: _stableId,
    clock: _clock,
  );

  void expectSalvage(String json, String messagePart) {
    final imported = importer.importDetailed(json);
    expect(imported.plan.source, PlanSource.imported);
    expect(
      imported.issues.map((i) => i.message).join('\n'),
      contains(messagePart),
    );
  }

  test('maps the canonical sample onto days, supersets, and common sections',
      () {
    final plan = importer.import(_sampleJson);

    expect(plan.title, 'plan 1');
    expect(plan.source, PlanSource.imported);
    expect(plan.createdAt, DateTime.utc(2026, 8, 26, 12));
    expect(plan.days, hasLength(3));

    final day = plan.days.first;
    expect(day.dayId, isNotEmpty);
    expect(day.title, 'day 1- 4sar');
    expect(day.blocks, hasLength(2));

    final superset = day.blocks[0];
    expect(superset.kind, BlockKind.superset);
    expect(superset.svgPath, isNull);
    expect(
      superset.exercises.first.mediaUri,
      'assets/image/exercises/kang-squat.png',
    );
    expect(superset.exercises.map((e) => e.title),
        ['kang squat', 'leg extension']);
    expect(superset.exercises.first.prescribedSets, 3);
    expect(superset.exercises.first.prescribedReps, 12);
    expect(superset.exercises.first.prescribedDurationSeconds, isNull);
    expect(superset.exercises.first.targetWeightKg, isNull);

    final single = day.blocks[1];
    expect(single.kind, BlockKind.single);
    expect(single.svgPath, isNull);
    expect(
      single.exercises.single.mediaUri,
      'assets/image/exercises/reverse-lunge-press.png',
    );
    expect(single.exercises.single.title, 'reverse lunges+ Press');
    expect(single.exercises.single.prescribedReps, 12);

    final abs = plan.days[1];
    expect(abs.title, 'abs');
    expect(abs.blocks.single.kind, BlockKind.single);
    expect(abs.blocks.single.svgPath, isNull);
    expect(
      abs.blocks.single.exercises.single.mediaUri,
      'assets/image/exercises/shoot-out.png',
    );
    expect(abs.blocks.single.exercises.single.title, 'shoot out');
    expect(abs.blocks.single.exercises.single.prescribedSets, 1);
    expect(abs.blocks.single.exercises.single.prescribedReps, isNull);
    expect(abs.blocks.single.exercises.single.prescribedDurationSeconds, 30);

    expect(plan.days[2].title, 'corrective');
    expect(
      plan.days[2].blocks.single.exercises.single.mediaUri,
      'assets/image/exercises/step-lunge-stretch.png',
    );
  });

  test('ignores the informational days count', () {
    final plan = importer.import(_sampleJson);
    expect(plan.days.first.title, 'day 1- 4sar');
    expect(plan.days.map((day) => day.title), containsAll(['abs', 'corrective']));
  });

  test('rejects a trailing comma with a readable error', () {
    expectSalvage('{ "name": "plan 1", }', 'syntax issues');
  });

  test('rejects a plan with no name', () {
    expectSalvage('{"basic-plan":[]}', 'needs a name');
  });

  test('rejects a plan with no days', () {
    expectSalvage('{"name":"empty","basic-plan":[]}', 'No days');
  });

  test('rejects an unknown block type', () {
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{ "type": "circuit", "exercise": {} }]
  }]
}
''', 'could not read');
  });

  test('rejects a super-set with one movement', () {
    expectSalvage('''
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
''', 'at least two exercises');
  });

  test('rejects an exercise that has both times and duration', () {
    expectSalvage('''
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
''', 'not both');
  });

  test('rejects an exercise with neither times nor duration', () {
    expectSalvage('''
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
''', 'times (reps) or duration');
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
    expect(plan.days, hasLength(1));
  });

  test('empty common-plan is valid and common-section errors are UI-safe', () {
    final emptyCommons = importer.import('''
{
  "name": "solo",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": []
}
''');
    expect(emptyCommons.days, hasLength(1));

    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": [{ "exercises": [] }]
}
''', 'Common section 1 needs a name');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": [{ "name": "abs" }]
}
''', 'needs an exercises list');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "super-set",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }]
}
''', 'needs a list of exercises');
  });

  test('accepts whole-number doubles for sets and times', () {
    final plan = importer.import('''
{
  "name": "numbers",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3.0, "times": 8.0, "duration": null }
    }]
  }]
}
''');
    final exercise = plan.days.single.blocks.single.exercises.single;
    expect(exercise.prescribedSets, 3);
    expect(exercise.prescribedReps, 8);
  });

  test('rejects zero or fractional load values', () {
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 0, "times": 8, "duration": null }
    }]
  }]
}
''', 'at least 1 set');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 0, "duration": null }
    }]
  }]
}
''', 'times must be at least 1');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "plank", "sets": 1, "times": null, "duration": 0 }
    }]
  }]
}
''', 'duration must be at least 1 second');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3.5, "times": 8, "duration": null }
    }]
  }]
}
''', 'must be a whole number');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "plank", "sets": 1, "times": null, "duration": 30.5 }
    }]
  }]
}
''', 'must be a whole number');
  });

  test('accepts a duration whole-number double and a three-move super-set', () {
    final plan = importer.import('''
{
  "name": "holds",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "super-set",
      "exercise": [
        { "title": "plank", "sets": 1, "times": null, "duration": 30.0 },
        { "title": "hollow hold", "sets": 1, "times": null, "duration": 45 },
        { "title": "dead bug", "sets": 2, "times": 10, "duration": null }
      ]
    }]
  }]
}
''');
    final block = plan.days.single.blocks.single;
    expect(block.kind, BlockKind.superset);
    expect(block.exercises.map((e) => e.title),
        ['plank', 'hollow hold', 'dead bug']);
    expect(block.exercises[0].prescribedDurationSeconds, 30);
    expect(block.exercises[0].prescribedReps, isNull);
    expect(block.exercises[1].prescribedDurationSeconds, 45);
    expect(block.exercises[2].prescribedReps, 10);
    expect(block.exercises[2].prescribedDurationSeconds, isNull);
  });

  test('rejects a common section that is missing a name or exercises list', () {
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": [{ "exercises": [] }]
}
''', 'needs a name');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": [{ "name": "abs" }]
}
''', 'needs an exercises list');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": ["abs"]
}
''', 'not a JSON object');
  });

  test('rejects missing structure with readable, UI-safe messages', () {
    expectSalvage('[]', 'not a JSON object');
    expectSalvage('{"name":"plan"}', 'No days found');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{ "exercises": [] }]
}
''', 'needs a name');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{ "name": "day 1" }]
}
''', 'needs an exercises list');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{ "exercise": { "title": "squat", "sets": 3, "times": 8 } }]
  }]
}
''', 'could not read');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "   ", "sets": 3, "times": 8, "duration": null }
    }]
  }]
}
''', 'needs an exercise title');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": [{ "title": "squat", "sets": 3, "times": 8, "duration": null }]
    }]
  }]
}
''', 'needs an exercise object');
  });

  test('rejects negative load values the same way as zeros', () {
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": -1, "times": 8, "duration": null }
    }]
  }]
}
''', 'at least 1 set');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": -8, "duration": null }
    }]
  }]
}
''', 'times must be at least 1');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "plank", "sets": 1, "times": null, "duration": -5 }
    }]
  }]
}
''', 'duration must be at least 1 second');
  });

  test('an empty exercises list is a rest day, and a string exercise is rejected',
      () {
    final rest = importer.import('''
{
  "name": "deload",
  "basic-plan": [{ "name": "rest", "exercises": [] }]
}
''');
    expect(rest.days.single.title, 'rest');
    expect(rest.days.single.blocks, isEmpty);

    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": ["squat"]
  }]
}
''', 'not a JSON object');
  });

  test('rejects a blank name and a non-array common-plan', () {
    expectSalvage('{"name":"   ","basic-plan":[]}', 'needs a name');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": {}
}
''', 'not a JSON array');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": [{ "name": "abs" }]
}
''', 'needs an exercises list');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": ["not a day"]
}
''', 'not a JSON object');
  });

  test('trims titles and leaves unmatched exercises without a preview asset',
      () {
    final plan = importer.import('''
{
  "name": "  Imported Plan  ",
  "basic-plan": [{
    "name": "  Day One  ",
    "exercises": [{
      "type": "single",
      "exercise": {
        "title": "  Mystery Move  ",
        "sets": 2,
        "times": 8,
        "duration": null
      }
    }]
  }],
  "common-plan": [{
    "name": "  Abs  ",
    "exercises": [{
      "type": "single",
      "exercise": {
        "title": "  plank  ",
        "sets": 1,
        "times": null,
        "duration": 30
      }
    }]
  }]
}
''');

    expect(plan.title, 'Imported Plan');
    expect(plan.days, hasLength(2));
    expect(plan.days.first.title, 'Day One');
    expect(plan.days.first.blocks.single.exercises.single.title, 'Mystery Move');
    expect(plan.days.first.blocks.single.svgPath, isNull);
    expect(plan.days.last.title, 'Abs');
    expect(
      plan.days.last.blocks.single.exercises.single.title,
      'plank',
    );
    expect(plan.days.last.blocks.single.svgPath, isNull);
    expect(
      plan.days.last.blocks.single.exercises.single.mediaUri,
      'assets/image/exercises/plank.png',
    );
  });

  test('rejects string or boolean load values and a non-object day', () {
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": "3", "times": 8, "duration": null }
    }]
  }]
}
''', 'must be a whole number');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": true, "duration": null }
    }]
  }]
}
''', 'must be a whole number');
    expectSalvage('''
{
  "name": "plan",
  "basic-plan": ["not a day object"]
}
''', 'Day 1 is not a JSON object');
  });

  test('an empty common-plan array is a plan with no extras, not an error', () {
    final plan = importer.import('''
{
  "name": "solo",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 8, "duration": null }
    }]
  }],
  "common-plan": []
}
''');
    expect(plan.days, hasLength(1));
    expect(plan.days.single.blocks.single.exercises.single.title, 'squat');
  });

  test('optional goals and target-areas are additive', () {
    final plan = importer.import('''
{
  "name": "Goals plan",
  "goals": ["build-strength", "mystery"],
  "description": "Heavy days",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": {
        "title": "bench press",
        "sets": 4,
        "times": 6,
        "target-areas": ["chest", "triceps"]
      }
    }]
  }]
}
''');
    expect(plan.goalIds, ['build-strength']);
    expect(plan.description, 'Heavy days');
    expect(
      plan.days.single.blocks.single.exercises.single.targetAreaIds,
      ['chest', 'triceps'],
    );
  });

  test('omitted target-areas auto-fill from the catalog', () {
    final plan = importer.import('''
{
  "name": "Auto",
  "basic-plan": [{
    "name": "day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "bench press", "sets": 3, "times": 8 }
    }]
  }]
}
''');
    expect(
      plan.days.single.blocks.single.exercises.single.targetAreaIds,
      ['chest', 'triceps', 'front-shoulders'],
    );
  });

  test('legacy common-plan becomes extra days and is listed on the detailed import',
      () {
    final imported = importer.importDetailed(_sampleJson);
    expect(
      imported.convertedCommonSectionTitles,
      ['abs', 'corrective'],
    );
    expect(
      imported.plan.days.map((day) => day.title),
      containsAll(['abs', 'corrective']),
    );
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
