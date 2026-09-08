import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/isar_catalog_repository.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/domain/models/catalog_exercise.dart';
import 'package:gym_app/domain/models/enums.dart';

import '../helpers/isar_core.dart';

void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_catalog_');
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

  test('Isar catalog round-trips a user exercise and promotion query', () async {
    instanceSeq += 1;
    final service = await IsarService.init(
      directory: tempDir!.path,
      name: 'catalog$instanceSeq',
    );
    Get.put(service);
    final catalog = IsarCatalogRepository(service.isar);

    final saved = await catalog.saveUser(
      CatalogExercise(
        id: '',
        title: 'Cable crunch',
        mediaUri: 'assets/image/exercises/crunches.png',
        mediaSource: ExerciseMediaSource.asset,
        mediaKind: ExerciseMediaKind.image,
        origin: CatalogOrigin.user,
        targetAreaIds: const ['abs'],
      ),
    );
    expect(saved.id, isNotEmpty);
    expect(await catalog.byId(saved.id), isNotNull);
    expect(
      (await catalog.userCreatedNotInBundled()).map((e) => e.title),
      ['Cable crunch'],
    );
    expect((await catalog.matchByTitle('cable crunch'))?.id, saved.id);
    expect(await catalog.deleteUser(saved.id), isTrue);
    expect(await catalog.byId(saved.id), isNull);
  });
}
