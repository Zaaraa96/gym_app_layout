import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';
import 'package:gym_app/data/models/models.dart';
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

  test('every bundled svg file is on disk', () {
    for (final asset in bundledExerciseAssets) {
      expect(File(asset.assetPath).existsSync(), isTrue, reason: asset.assetPath);
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
    expect(blockSvgPath(block), 'assets/image/exercises/kang-squat.svg');
  });

  testWidgets('every exercise icon paints without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            for (final asset in bundledExerciseAssets)
              SvgPicture.asset(
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
}
