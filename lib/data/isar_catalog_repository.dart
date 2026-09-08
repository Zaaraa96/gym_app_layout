import 'package:isar/isar.dart';

import '../common/exercise_asset_catalog.dart';
import '../domain/catalog_query.dart';
import '../domain/catalog_repository.dart';
import '../domain/catalog_write.dart';
import '../domain/models/catalog_exercise.dart';
import '../domain/new_id.dart';
import 'isar/catalog_mappers.dart';
import 'isar/user_catalog_exercise.dart';

/// Isar-backed [CatalogRepository]. Bundled movements stay in Dart.
class IsarCatalogRepository implements CatalogRepository {
  IsarCatalogRepository(this._isar);

  final Isar _isar;

  @override
  Future<List<CatalogExercise>> all() async => _merged(await _userRows());

  @override
  Future<CatalogExercise?> byId(String id) async {
    for (final item in await all()) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<CatalogExercise?> matchByTitle(String? title) async =>
      bestCatalogMatch(title, await all());

  @override
  Future<List<CatalogExercise>> search({
    String query = '',
    Set<String> regionIds = const {},
    Set<String> targetAreaIds = const {},
  }) async {
    return filterCatalogExercises(
      await all(),
      query: query,
      regionIds: regionIds,
      targetAreaIds: targetAreaIds,
    );
  }

  @override
  Future<CatalogExercise> saveUser(CatalogExercise exercise) async {
    final prepared = prepareUserCatalogExercise(exercise);
    final id = prepared.id.trim().isEmpty ? newUuid() : prepared.id;
    final toSave = copyUserCatalogExercise(prepared, id: id);
    validateUserCatalogExercise(
      exercise: toSave,
      existing: await all(),
    );
    final existing = await _isar.userCatalogExercises
        .filter()
        .uuidEqualTo(toSave.id)
        .findFirst();
    if (existing != null) {
      toSave.localId = existing.id;
      toSave.createdAt = existing.createdAt;
    }
    final row = catalogExerciseToIsar(toSave);
    await _isar.writeTxn(() async {
      final localId = await _isar.userCatalogExercises.put(row);
      toSave.localId = localId;
    });
    await onUserExerciseAdded(toSave);
    return toSave;
  }

  @override
  Future<bool> deleteUser(String id) async {
    final row = await _isar.userCatalogExercises
        .filter()
        .uuidEqualTo(id)
        .findFirst();
    if (row == null) return false;
    return _isar.writeTxn(() => _isar.userCatalogExercises.delete(row.id));
  }

  @override
  Stream<void> watch({bool fireImmediately = false}) =>
      _isar.userCatalogExercises.watchLazy(fireImmediately: fireImmediately);

  @override
  Future<void> onUserExerciseAdded(CatalogExercise exercise) async {
    // Persist-only in this slice. A later adapter can upload/export [exercise].
  }

  @override
  Future<List<CatalogExercise>> userCreatedNotInBundled() async {
    return [
      for (final row in await _userRows())
        if (row.hasPicture && isPromotionCandidate(row)) row,
    ];
  }

  Future<List<CatalogExercise>> _userRows() async {
    final rows = await _isar.userCatalogExercises.where().findAll();
    return [for (final row in rows) catalogExerciseFromIsar(row)];
  }

  List<CatalogExercise> _merged(List<CatalogExercise> userRows) {
    return [
      ...bundledCatalogExercises(),
      for (final row in userRows)
        if (row.hasPicture) row,
    ];
  }
}
