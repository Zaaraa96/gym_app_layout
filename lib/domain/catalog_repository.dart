import 'models/catalog_exercise.dart';

/// Merged exercise catalog: bundled stills/GIFs plus user-created rows.
///
/// UI binds to this type, not a remote store. The later plan-exercise editor
/// pre-fills from [byId] / [matchByTitle].
abstract class CatalogRepository {
  /// Supported movements (those with a picture), bundled then user-created.
  Future<List<CatalogExercise>> all();

  Future<CatalogExercise?> byId(String id);

  /// Best alias/title match across the merged catalog.
  Future<CatalogExercise?> matchByTitle(String? title);

  Future<List<CatalogExercise>> search({
    String query = '',
    Set<String> regionIds = const {},
    Set<String> targetAreaIds = const {},
  });

  /// Persists a user-created row, then calls [onUserExerciseAdded].
  Future<CatalogExercise> saveUser(CatalogExercise exercise);

  Future<bool> deleteUser(String id);

  Stream<void> watch({bool fireImmediately = false});

  /// Called after a successful user add (and after a user edit that changes
  /// title, media, or tags). Default: persist only. Later a sync/export
  /// adapter can implement this without changing the Add UI.
  Future<void> onUserExerciseAdded(CatalogExercise exercise);

  /// User-created rows that do not already match a bundled id or alias.
  /// This is how a later version (or an export tool) finds promotion candidates.
  Future<List<CatalogExercise>> userCreatedNotInBundled();
}
