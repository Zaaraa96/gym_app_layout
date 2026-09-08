import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/memory_catalog_repository.dart';
import 'package:gym_app/domain/catalog_write.dart';
import 'package:gym_app/domain/models/catalog_exercise.dart';
import 'package:gym_app/domain/models/enums.dart';

CatalogExercise _user({
  String id = '',
  String title = 'Cable crunch',
  List<String> targets = const ['abs'],
  String media = 'assets/image/exercises/crunches.png',
}) {
  return CatalogExercise(
    id: id,
    title: title,
    mediaUri: media,
    mediaSource: ExerciseMediaSource.asset,
    mediaKind: ExerciseMediaKind.image,
    origin: CatalogOrigin.user,
    targetAreaIds: targets,
  );
}

void main() {
  test('all() starts with the thirty bundled stills', () async {
    final catalog = MemoryCatalogRepository();
    final items = await catalog.all();
    expect(items, hasLength(30));
    expect(items.every((item) => item.isBundled), isTrue);
    expect(await catalog.byId('plank'), isNotNull);
    expect((await catalog.matchByTitle('rdl'))?.id, 'romanian-deadlift');
  });

  test('saveUser requires a picture and calls onUserExerciseAdded', () async {
    final catalog = MemoryCatalogRepository();
    expect(
      catalog.saveUser(_user(media: '', title: 'No photo')),
      throwsA(isA<CatalogWriteException>()),
    );

    final saved = await catalog.saveUser(_user());
    expect(saved.isUserCreated, isTrue);
    expect(saved.id, isNotEmpty);
    expect(saved.regionIds, contains('abs'));
    expect(catalog.promotionEvents, hasLength(1));
    expect(catalog.promotionEvents.single.title, 'Cable crunch');
    expect(await catalog.byId(saved.id), isNotNull);

    final candidates = await catalog.userCreatedNotInBundled();
    expect(candidates.map((e) => e.title), ['Cable crunch']);
  });

  test('duplicate bundled titles are rejected', () async {
    final catalog = MemoryCatalogRepository();
    expect(
      catalog.saveUser(_user(title: 'Plank')),
      throwsA(isA<CatalogWriteException>()),
    );
  });

  test('search and matchByTitle include user rows', () async {
    final catalog = MemoryCatalogRepository();
    final saved = await catalog.saveUser(_user());
    final found = await catalog.search(query: 'cable');
    expect(found.single.id, saved.id);
    expect((await catalog.matchByTitle('Cable crunch'))?.id, saved.id);
  });

  test('userCreatedNotInBundled returns custom titles that are not bundled',
      () async {
    final catalog = MemoryCatalogRepository();
    await catalog.saveUser(_user(title: 'Cable crunch'));
    final candidates = await catalog.userCreatedNotInBundled();
    expect(candidates.map((e) => e.title), ['Cable crunch']);
  });

  test('deleteUser removes a custom exercise from the merged list', () async {
    final catalog = MemoryCatalogRepository();
    final saved = await catalog.saveUser(_user());
    expect(await catalog.deleteUser(saved.id), isTrue);
    expect(await catalog.byId(saved.id), isNull);
    expect(await catalog.userCreatedNotInBundled(), isEmpty);
  });
}
