import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/plans/exercise_asset_catalog.dart';
import 'package:gym_app/features/plans/exercise_media.dart';
import 'package:gym_app/features/plans/exercise_media_picker.dart';

void main() {
  test('bundled exercise catalog contains 30 SVG assets', () {
    expect(bundledExerciseAssets, hasLength(30));
    for (final entry in bundledExerciseAssets) {
      expect(entry.assetPath, endsWith('.svg'));
      expect(entry.assetPath, startsWith('assets/image/exercises/'));
    }
  });

  test('bestAssetMatchForTitle finds relevant bundled icons', () {
    expect(bestAssetMatchForTitle('bench press')?.id, 'bench-press');
    expect(bestAssetMatchForTitle('plank hold')?.id, 'plank');
    expect(bestAssetMatchForTitle('random move'), isNull);
  });

  test('resolveBlockMedia prefers explicit media fields over legacy svgPath',
      () {
    final block = ExerciseBlock.create(
      blockId: 'b1',
      kind: BlockKind.single,
      svgPath: 'assets/image/upper-body.svg',
      mediaUri: 'assets/image/exercises/squat.svg',
      mediaSource: ExerciseMediaSource.asset,
      mediaKind: ExerciseMediaKind.svg,
      exercises: [],
    );

    final media = resolveBlockMedia(block);
    expect(media.uri, 'assets/image/exercises/squat.svg');
    expect(media.kind, ExerciseMediaKind.svg);
  });

  test('PickedExerciseMedia round-trips through ExerciseBlock', () {
    final block = ExerciseBlock.create(
      blockId: 'b1',
      kind: BlockKind.single,
      exercises: [],
    );

    PickedExerciseMedia.network('https://example.com/demo.gif').applyTo(block);
    expect(block.mediaSource, ExerciseMediaSource.network);
    expect(block.mediaKind, ExerciseMediaKind.gif);
    expect(block.mediaUri, 'https://example.com/demo.gif');

    final restored = PickedExerciseMedia.fromBlock(block);
    expect(restored?.uri, 'https://example.com/demo.gif');
    expect(restored?.source, ExerciseMediaSource.network);

    PickedExerciseMedia.clearBlock(block);
    expect(block.mediaSource, ExerciseMediaSource.none);
    expect(block.mediaUri, isNull);
  });
}
