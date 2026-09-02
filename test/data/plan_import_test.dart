import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/data/plan_import.dart';
import 'package:gym_app/data/plan_import_picker.dart';

class _Picker implements PlanImportPicker {
  _Picker({this.file, this.error});

  PickedPlanFile? file;
  Object? error;

  @override
  Future<PickedPlanFile?> pick() async {
    if (error != null) throw error!;
    return file;
  }
}

void main() {
  const validJson = '''
{
  "name": "Imported",
  "basic-plan": [{
    "name": "Day 1",
    "exercises": [{
      "type": "single",
      "exercise": { "title": "squat", "sets": 3, "times": 10 }
    }]
  }]
}
''';

  test('cancel leaves no parsed plan', () async {
    final import = PlanImport(
      picker: _Picker(),
      plans: MemoryPlanRepository(),
    );
    expect(await import.pickAndParse(), isA<PlanImportCancelled>());
  });

  test('picker errors become a message safe to show', () async {
    final import = PlanImport(
      picker: _Picker(error: const PlanImportException('Could not read that file.')),
      plans: MemoryPlanRepository(),
    );
    final outcome = await import.pickAndParse();
    expect(
      outcome,
      isA<PlanImportFailed>().having(
        (failed) => failed.message,
        'message',
        'Could not read that file.',
      ),
    );
  });

  test('invalid JSON is a failed outcome, not a thrown exception', () async {
    final import = PlanImport(
      picker: _Picker(
        file: const PickedPlanFile(
          fileName: 'bad.json',
          contents: '{ "name": "plan 1", }',
        ),
      ),
      plans: MemoryPlanRepository(),
    );
    final outcome = await import.pickAndParse();
    expect(
      outcome,
      isA<PlanImportFailed>().having(
        (failed) => failed.message,
        'message',
        contains('not valid JSON'),
      ),
    );
  });

  test('valid JSON parses then save writes the plan', () async {
    final plans = MemoryPlanRepository();
    final import = PlanImport(
      picker: _Picker(
        file: const PickedPlanFile(fileName: 'plan.json', contents: validJson),
      ),
      plans: plans,
    );

    final outcome = await import.pickAndParse();
    expect(outcome, isA<PlanImportParsed>());
    final parsed = outcome as PlanImportParsed;
    expect(parsed.fileName, 'plan.json');
    expect(parsed.plan.title, 'Imported');
    expect(parsed.plan.days.single.title, 'Day 1');

    final saved = await import.save(parsed.plan);
    expect(await plans.count(), 1);
    expect((await plans.byUuid(saved.uuid))?.title, 'Imported');
  });
}
