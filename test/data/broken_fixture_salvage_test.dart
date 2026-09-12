import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/json_plan_importer.dart';

void main() {
  test('patrol broken.json fixture salvages into a draft with issues', () {
    final source = File('tool/fixtures/invalid-plan.json').readAsStringSync();
    final imported = const JsonPlanImporter().importDetailed(source);
    expect(imported.plan.title, 'plan 1');
    expect(imported.issues, isNotEmpty);
  });

  test('old garbage text would still fail', () {
    expect(
      () => const JsonPlanImporter().importDetailed('not json at all'),
      throwsA(isA<PlanImportException>()),
    );
  });
}
