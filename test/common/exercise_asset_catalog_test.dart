import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/block_summary.dart';

void main() {
  test('ships thirty unique exercise icons', () {
    expect(bundledExerciseAssets, hasLength(30));
    expect(
      bundledExerciseAssets.map((asset) => asset.id).toSet(),
      hasLength(30),
    );
    expect(
      bundledExerciseAssets.map((asset) => asset.assetPath).toSet(),
      hasLength(30),
    );
  });

  test('every bundled still and gif file is on disk', () {
    for (final asset in bundledExerciseAssets) {
      expect(File(asset.assetPath).existsSync(), isTrue, reason: asset.assetPath);
      expect(File(asset.gifPath).existsSync(), isTrue, reason: asset.gifPath);
    }
  });

  test('matches sample-plan titles to the designed assets', () {
    expect(matchExerciseAsset('kang squat')?.id, 'kang-squat');
    expect(matchExerciseAsset('leg extension')?.id, 'leg-extension');
    expect(matchExerciseAsset('reverse lunges+ Press')?.id, 'reverse-lunge-press');
    expect(matchExerciseAsset('shoot out')?.id, 'shoot-out');
    expect(matchExerciseAsset('step lunge stretch')?.id, 'step-lunge-stretch');
    expect(matchExerciseAsset('squat')?.id, 'squat');
    expect(matchExerciseAsset('plank')?.id, 'plank');
    expect(matchExerciseAsset('unknown move'), isNull);
  });

  test('matches titles on word boundaries so shorter names do not steal longer ones',
      () {
    expect(matchExerciseAsset('lunge')?.id, 'lunge');
    expect(matchExerciseAsset('walking lunges')?.id, 'lunge');
    expect(matchExerciseAsset('deadlift')?.id, 'deadlift');
    expect(matchExerciseAsset('romanian deadlift')?.id, 'romanian-deadlift');
    expect(matchExerciseAsset('rdl')?.id, 'romanian-deadlift');
    expect(matchExerciseAsset('Push-up!')?.id, 'push-up');
    expect(matchExerciseAsset('planks'), isNull);
    expect(matchExerciseAsset(''), isNull);
    expect(matchExerciseAsset(null), isNull);
  });

  test('suggestedAssetsForTitle puts the best match first', () {
    final suggested = suggestedAssetsForTitle('heavy deadlift');
    expect(suggested.first.id, 'deadlift');
    expect(suggested, hasLength(bundledExerciseAssets.length));
    expect(suggested.where((asset) => asset.id == 'deadlift'), hasLength(1));
  });

  test('bundledAssetByPath finds stills and form gifs', () {
    expect(
      bundledAssetByPath('assets/image/exercises/plank.png')?.id,
      'plank',
    );
    expect(
      bundledAssetByPath('assets/image/exercises/gifs/plank.gif')?.id,
      'plank',
    );
    expect(bundledAssetByPath('assets/image/upper-body.svg'), isNull);
    expect(bundledAssetByPath(''), isNull);
    expect(bundledAssetByPath(null), isNull);
  });

  test('day rows use the matched icon when svgPath is empty', () {
    final block = ExerciseBlock.create(
      blockId: 'b1',
      kind: BlockKind.single,
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'p1',
          title: 'kang squat',
          prescribedSets: 3,
          prescribedReps: 12,
        ),
      ],
    );
    expect(blockSvgPath(block), 'assets/image/exercises/kang-squat.png');
  });

  testWidgets('every exercise icon paints without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            for (final asset in bundledExerciseAssets)
              Image.asset(
                asset.assetPath,
                width: 40,
                height: 40,
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every exercise form gif decodes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            for (final asset in bundledExerciseAssets)
              Image.asset(
                asset.gifPath,
                width: 64,
                height: 64,
                gaplessPlayback: true,
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
