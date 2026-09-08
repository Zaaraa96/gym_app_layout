import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';
import 'package:gym_app/domain/catalog_query.dart';
import 'package:gym_app/domain/catalog_write.dart';
import 'package:gym_app/domain/models/catalog_exercise.dart';
import 'package:gym_app/domain/models/enums.dart';
import 'package:gym_app/domain/plan_catalog.dart';

void main() {
  test('every bundled entry has regions, targets, and a default prescription',
      () {
    expect(bundledExerciseAssets, hasLength(30));
    for (final asset in bundledExerciseAssets) {
      expect(asset.targetAreaIds, isNotEmpty, reason: asset.id);
      expect(asset.regionIds, isNotEmpty, reason: asset.id);
      expect(asset.defaultSets, greaterThanOrEqualTo(1), reason: asset.id);
      if (asset.prescriptionType == PrescriptionType.timed) {
        expect(asset.defaultReps, isNull, reason: asset.id);
        expect(asset.defaultDurationSeconds, greaterThanOrEqualTo(1),
            reason: asset.id);
      } else {
        expect(asset.defaultReps, greaterThanOrEqualTo(1), reason: asset.id);
        expect(asset.defaultDurationSeconds, isNull, reason: asset.id);
      }
    }
  });

  test('region mapping covers hybrids and cardio extras', () {
    expect(
      defaultRegionIdsFor(['quads', 'front-shoulders']),
      ['upper', 'lower'],
    );
    final squat = bundledExerciseAssets.firstWhere((e) => e.id == 'squat');
    expect(squat.regionIds, ['lower']);
    final press = bundledExerciseAssets
        .firstWhere((e) => e.id == 'reverse-lunge-press');
    expect(press.regionIds, containsAll(['upper', 'lower']));
    final box = bundledExerciseAssets.firstWhere((e) => e.id == 'box-jump');
    expect(box.regionIds, containsAll(['lower', 'cardio']));
    final plank = bundledExerciseAssets.firstWhere((e) => e.id == 'plank');
    expect(plank.regionIds, ['abs']);
    expect(plank.prescriptionType, PrescriptionType.timed);
  });

  test('region filter is a union and muscle chips further restrict', () {
    final items = bundledCatalogExercises();
    final abs = filterCatalogExercises(items, regionIds: {'abs'});
    expect(abs.map((e) => e.id), containsAll(['plank', 'crunches']));
    expect(abs.map((e) => e.id), isNot(contains('squat')));

    final upperOrLower = filterCatalogExercises(
      items,
      regionIds: {'upper', 'lower'},
    );
    expect(upperOrLower.map((e) => e.id), contains('squat'));
    expect(upperOrLower.map((e) => e.id), contains('bench-press'));
    expect(upperOrLower.map((e) => e.id), contains('reverse-lunge-press'));

    final chest = filterCatalogExercises(
      items,
      regionIds: {'upper'},
      targetAreaIds: {'chest'},
    );
    expect(chest.map((e) => e.id), contains('bench-press'));
    expect(chest.map((e) => e.id), isNot(contains('bicep-curl')));
  });

  test('search matches aliases and ignores entries without a picture', () {
    final items = [
      ...bundledCatalogExercises(),
      CatalogExercise(
        id: 'ghost',
        title: 'Ghost move',
        mediaUri: '',
        mediaSource: ExerciseMediaSource.none,
        origin: CatalogOrigin.user,
        targetAreaIds: const ['abs'],
      ),
    ];
    final rdl = filterCatalogExercises(items, query: 'rdl');
    expect(rdl.single.id, 'romanian-deadlift');
    expect(filterCatalogExercises(items, query: 'ghost'), isEmpty);
  });

  test('matchByTitle scoring still prefers the longer bundled phrase', () {
    final items = bundledCatalogExercises();
    expect(bestCatalogMatch('rdl', items)?.id, 'romanian-deadlift');
    expect(bestCatalogMatch('kang squat', items)?.id, 'kang-squat');
    expect(bestCatalogMatch('unknown move', items), isNull);
  });

  test('promotion candidates skip titles that already ship bundled', () {
    final custom = CatalogExercise(
      id: 'user-1',
      title: 'Cable crunch',
      mediaUri: 'assets/image/exercises/crunches.png',
      origin: CatalogOrigin.user,
      targetAreaIds: const ['abs'],
    );
    expect(isPromotionCandidate(custom), isTrue);
    final alreadyShipped = CatalogExercise(
      id: 'user-2',
      title: 'Plank',
      mediaUri: 'assets/image/exercises/plank.png',
      origin: CatalogOrigin.user,
      targetAreaIds: const ['abs'],
    );
    expect(isPromotionCandidate(alreadyShipped), isFalse);
  });

  test('validateUserCatalogExercise requires name, picture, and a target', () {
    final bundled = bundledCatalogExercises();
    expect(
      () => validateUserCatalogExercise(
        exercise: CatalogExercise(
          id: 'n',
          title: '',
          mediaUri: 'assets/image/exercises/plank.png',
          origin: CatalogOrigin.user,
          targetAreaIds: const ['abs'],
        ),
        existing: bundled,
      ),
      throwsA(isA<CatalogWriteException>()),
    );
    expect(
      () => validateUserCatalogExercise(
        exercise: CatalogExercise(
          id: 'n',
          title: 'Cable crunch',
          mediaUri: '',
          mediaSource: ExerciseMediaSource.none,
          origin: CatalogOrigin.user,
          targetAreaIds: const ['abs'],
        ),
        existing: bundled,
      ),
      throwsA(isA<CatalogWriteException>()),
    );
    expect(
      () => validateUserCatalogExercise(
        exercise: CatalogExercise(
          id: 'n',
          title: 'Plank',
          mediaUri: 'assets/image/exercises/plank.png',
          origin: CatalogOrigin.user,
          targetAreaIds: const ['abs'],
        ),
        existing: bundled,
      ),
      throwsA(
        isA<CatalogWriteException>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        ),
      ),
    );
  });
}
