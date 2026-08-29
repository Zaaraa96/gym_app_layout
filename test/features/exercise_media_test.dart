import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/features/plans/exercise_asset_catalog.dart';
import 'package:gym_app/features/plans/exercise_media.dart';
import 'package:gym_app/features/plans/exercise_media_picker.dart';

void main() {
  test('bundled exercise catalog contains 30 illustrated stills', () {
    expect(bundledExerciseAssets, hasLength(30));
    for (final entry in bundledExerciseAssets) {
      expect(entry.assetPath, endsWith('.png'));
      expect(entry.assetPath, startsWith('assets/image/exercises/'));
      expect(entry.gifPath, endsWith('.gif'));
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
      mediaUri: 'assets/image/exercises/squat.png',
      mediaSource: ExerciseMediaSource.asset,
      mediaKind: ExerciseMediaKind.image,
      exercises: [],
    );

    final media = resolveBlockMedia(block);
    expect(media.uri, 'assets/image/exercises/squat.png');
    expect(media.kind, ExerciseMediaKind.image);
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

  test('resolveBlockMedia ignores unset media fields and falls back in order',
      () {
    final untitled = ExerciseBlock.create(
      blockId: 'b1',
      kind: BlockKind.single,
      mediaUri: 'assets/image/exercises/squat.png',
      mediaSource: ExerciseMediaSource.none,
      mediaKind: ExerciseMediaKind.unknown,
      svgPath: 'assets/image/upper-body.svg',
      exercises: [],
    );
    expect(resolveBlockMedia(untitled).uri, 'assets/image/upper-body.svg');
    expect(resolveBlockMedia(untitled).kind, ExerciseMediaKind.svg);

    final matched = ExerciseBlock.create(
      blockId: 'b2',
      kind: BlockKind.single,
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'p1',
          title: 'plank',
          prescribedSets: 1,
          prescribedDurationSeconds: 30,
        ),
      ],
    );
    expect(resolveBlockMedia(matched).uri, 'assets/image/exercises/plank.png');
    expect(selectedBundledAsset(matched)?.id, 'plank');

    final unknown = ExerciseBlock.create(
      blockId: 'b3',
      kind: BlockKind.single,
      mediaUri: '   ',
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'p2',
          title: 'mystery move',
          prescribedSets: 3,
          prescribedReps: 10,
        ),
      ],
    );
    expect(resolveBlockMedia(unknown).uri, defaultBlockSvg);
    expect(resolveBlockMedia(unknown).kind, ExerciseMediaKind.svg);
  });

  test('kindForPath and kindForNetworkUrl classify extensions including query strings',
      () {
    expect(kindForPath('clip.SVG'), ExerciseMediaKind.svg);
    expect(kindForPath('demo.GIF'), ExerciseMediaKind.gif);
    expect(kindForPath('still.PNG'), ExerciseMediaKind.image);
    expect(kindForPath('form.mp4'), ExerciseMediaKind.video);
    expect(kindForPath('form.webm'), ExerciseMediaKind.video);
    expect(
      kindForNetworkUrl('https://cdn.example.com/form.gif?token=abc'),
      ExerciseMediaKind.gif,
    );
    expect(
      kindForNetworkUrl('https://cdn.example.com/form.mp4?exp=1'),
      ExerciseMediaKind.video,
    );
  });

  test('applying an asset keeps svgPath; gallery and network clear it', () {
    final block = ExerciseBlock.create(
      blockId: 'b1',
      kind: BlockKind.single,
      svgPath: 'assets/image/upper-body.svg',
      exercises: [],
    );

    PickedExerciseMedia.asset('assets/image/exercises/deadlift.png').applyTo(block);
    expect(block.svgPath, 'assets/image/exercises/deadlift.png');
    expect(block.mediaSource, ExerciseMediaSource.asset);
    expect(block.mediaKind, ExerciseMediaKind.image);

    PickedExerciseMedia.galleryFile(
      uri: '/tmp/photo.jpg',
      kind: ExerciseMediaKind.image,
    ).applyTo(block);
    expect(block.svgPath, isNull);
    expect(block.mediaSource, ExerciseMediaSource.gallery);

    final legacyOnly = ExerciseBlock.create(
      blockId: 'b2',
      kind: BlockKind.single,
      svgPath: 'assets/image/exercises/squat.png',
      exercises: [],
    );
    final restored = PickedExerciseMedia.fromBlock(legacyOnly);
    expect(restored?.source, ExerciseMediaSource.asset);
    expect(restored?.uri, 'assets/image/exercises/squat.png');
  });
}
