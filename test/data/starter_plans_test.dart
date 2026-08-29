import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/data/starter_plans.dart';

import '../helpers/isar_core.dart';

void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_starters_');
  });

  tearDown(() async {
    if (Get.isRegistered<IsarService>()) {
      await IsarService.to.close(deleteFromDisk: true);
    }
    Get.reset();
  });

  tearDownAll(() async {
    final dir = tempDir;
    if (dir != null && dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('bundled beginner full body is a valid 3-day import', () {
    final source =
        File('assets/json/beginner-full-body.json').readAsStringSync();
    final plan = const JsonPlanImporter().import(source);
    expect(plan.title, starterFullBody.title);
    expect(plan.days, hasLength(3));
    expect(
      plan.days.first.blocks.first.exercises.first.title,
      'Bodyweight squat',
    );
    expect(plan.commonSections.map((s) => s.title), ['abs', 'mobility']);
  });

  test('bundled beginner 2-day is a valid import with no commons', () {
    final source = File('assets/json/beginner-two-day.json').readAsStringSync();
    final plan = const JsonPlanImporter().import(source);
    expect(plan.title, starterTwoDay.title);
    expect(plan.days, hasLength(2));
    expect(plan.commonSections, isEmpty);
  });

  test('installStarterPlan saves once and reuses the same title', () async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'starters$instanceSeq',
    );
    Get.put(service);
    final plans = putPlans(service.isar);

    Future<String> load(String path) => File(path).readAsString();

    final first = await installStarterPlan(
      starterFullBody,
      plans: plans,
      loadAsset: load,
    );
    expect(first.title, starterFullBody.title);
    expect(first.days, hasLength(3));
    expect(first.id, greaterThan(0));

    final second = await installStarterPlan(
      starterFullBody,
      plans: plans,
      loadAsset: load,
    );
    expect(second.id, first.id);
    expect(await plans.count(), 1);
  });
}
