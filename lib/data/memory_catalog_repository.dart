import 'dart:async';

import '../common/exercise_asset_catalog.dart';
import '../domain/catalog_query.dart';
import '../domain/catalog_repository.dart';
import '../domain/catalog_write.dart';
import '../domain/models/catalog_exercise.dart';
import '../domain/models/workout_plan.dart';
import '../domain/new_id.dart';

/// In-memory [CatalogRepository] for tests and Flutter web.
class MemoryCatalogRepository implements CatalogRepository {
  final _byUuid = <String, CatalogExercise>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  /// Successful [saveUser] results, in order. Used by tests and as the
  /// default harvest log until a sync adapter implements [onUserExerciseAdded].
  final promotionEvents = <CatalogExercise>[];

  @override
  Future<List<CatalogExercise>> all() async => _merged();

  @override
  Future<CatalogExercise?> byId(String id) async {
    for (final item in _merged()) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<CatalogExercise?> matchByTitle(String? title) async =>
      bestCatalogMatch(title, _merged());

  @override
  Future<List<CatalogExercise>> search({
    String query = '',
    Set<String> regionIds = const {},
    Set<String> targetAreaIds = const {},
  }) async {
    return filterCatalogExercises(
      _merged(),
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
      existing: _merged(),
    );
    final previous = _byUuid[toSave.id];
    if (previous != null) {
      toSave.localId = previous.localId;
      toSave.createdAt = previous.createdAt;
    } else if (toSave.localId == unassignedLocalId) {
      toSave.localId = ++_nextId;
    }
    _byUuid[toSave.id] = toSave;
    _changes.add(null);
    await onUserExerciseAdded(toSave);
    return toSave;
  }

  @override
  Future<bool> deleteUser(String id) async {
    final removed = _byUuid.remove(id) != null;
    if (removed) _changes.add(null);
    return removed;
  }

  @override
  Stream<void> watch({bool fireImmediately = false}) async* {
    if (fireImmediately) yield null;
    yield* _changes.stream;
  }

  @override
  Future<void> onUserExerciseAdded(CatalogExercise exercise) async {
    promotionEvents.add(exercise);
  }

  @override
  Future<List<CatalogExercise>> userCreatedNotInBundled() async {
    return [
      for (final row in _byUuid.values)
        if (row.hasPicture && isPromotionCandidate(row)) row,
    ];
  }

  List<CatalogExercise> _merged() {
    return [
      ...bundledCatalogExercises(),
      for (final row in _byUuid.values)
        if (row.hasPicture) row,
    ];
  }
}

