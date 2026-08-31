import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_plan_repository.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';

import '../helpers/isar_core.dart';

/// [IsarPlanRepository] dirty/uuid/sync writes that UI and [SyncService] rely on.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_plans_');
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

  Future<PlanRepository> open() async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'plans$instanceSeq',
    );
    Get.put(service);
    return IsarPlanRepository(service.isar);
  }

  test('save marks dirty, assigns a uuid, and bumps updatedAt', () async {
    final plans = await open();
    final plan = WorkoutPlan.create(
      uuid: '',
      dirty: false,
      title: 'push',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2020, 1, 1),
    );

    await plans.save(plan);
    expect(plan.uuid, isNotEmpty);
    expect(plan.dirty, isTrue);
    expect(plan.updatedAt.isAfter(DateTime.utc(2020, 1, 1)), isTrue);
    expect((await plans.byUuid(plan.uuid))?.id, plan.id);
    expect((await plans.byId(plan.id))!.title, 'push');
    expect((await plans.unsynced()).map((row) => row.id), [plan.id]);
    expect(await plans.count(), 1);
  });

  test('putSynced keeps timestamps, clears dirty, and all() is newest first',
      () async {
    final plans = await open();
    final older = WorkoutPlan.create(
      uuid: 'older',
      title: 'older',
      source: PlanSource.created,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final newer = WorkoutPlan.create(
      uuid: 'newer',
      title: 'newer',
      source: PlanSource.imported,
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    );

    await plans.putSynced(older);
    await plans.putSynced(newer);

    expect(newer.dirty, isFalse);
    expect(newer.updatedAt.isAtSameMomentAs(DateTime.utc(2026, 8, 20)), isTrue);
    expect(await plans.unsynced(), isEmpty);
    expect((await plans.all()).map((row) => row.uuid), ['newer', 'older']);

    expect(await plans.delete(older.id), isTrue);
    expect(await plans.byUuid('older'), isNull);
    expect(await plans.count(), 1);
  });
}
