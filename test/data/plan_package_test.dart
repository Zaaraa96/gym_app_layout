import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/exercise_media_store.dart';
import 'package:gym_app/data/jpeg_exif.dart';
import 'package:gym_app/data/json_plan_importer.dart';
import 'package:gym_app/data/plan_package_exporter.dart';
import 'package:gym_app/data/plan_package_importer.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/domain/new_id.dart';

void main() {
  test('strips JPEG APP1 EXIF and leaves the SOI marker', () {
    final jpeg = Uint8List.fromList([
      0xFF, 0xD8,
      0xFF, 0xE1, 0x00, 0x06, 0x45, 0x78, 0x69, 0x66,
      0xFF, 0xDA, 0x00, 0x02, 0x00,
    ]);
    final stripped = stripJpegExif(jpeg);
    expect(stripped[0], 0xFF);
    expect(stripped[1], 0xD8);
    expect(stripped, isNot(containsAll([0x45, 0x78, 0x69, 0x66])));
    expect(stripped[2], 0xFF);
    expect(stripped[3], 0xDA);
  });

  test('zip round-trip keeps bundled ids and copies user files', () async {
    final dir = await Directory.systemTemp.createTemp('gym_pkg_');
    addTearDown(() => dir.delete(recursive: true));
    final gif = File('${dir.path}/form.gif');
    await gif.writeAsBytes([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00]);

    final now = DateTime.utc(2026, 9, 8);
    final plan = WorkoutPlan.create(
      title: 'Share me',
      source: PlanSource.created,
      status: PlanStatus.active,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'd1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p1',
                  title: 'squat',
                  prescribedSets: 3,
                  prescribedReps: 8,
                  catalogExerciseId: 'squat',
                  mediaUri: 'assets/image/exercises/squat.png',
                  mediaSource: ExerciseMediaSource.asset,
                  mediaKind: ExerciseMediaKind.image,
                ),
              ],
            ),
            ExerciseBlock.create(
              blockId: 'b2',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p2',
                  title: 'custom curl',
                  prescribedSets: 3,
                  prescribedReps: 10,
                  mediaUri: gif.path,
                  mediaSource: ExerciseMediaSource.gallery,
                  mediaKind: ExerciseMediaKind.gif,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final built = await const PlanPackageExporter().exportZip(plan);
    expect(built.fileName, 'share-me.gymplan');
    expect(plan.days.first.blocks.last.exercises.single.mediaUri, gif.path);

    final mediaDir = Directory('${dir.path}/docs');
    final imported = await PlanPackageImporter(
      jsonImporter: JsonPlanImporter(newId: newId, clock: () => now),
      mediaStore: ExerciseMediaStore(documentsPath: mediaDir.path),
    ).importBytes(built.bytes, fileName: built.fileName);

    expect(imported.plan.title, 'Share me');
    expect(imported.plan.status, PlanStatus.draft);
    final squat = imported.plan.days.single.blocks.first.exercises.single;
    expect(squat.catalogExerciseId, 'squat');
    expect(squat.mediaSource, ExerciseMediaSource.asset);
    expect(squat.mediaUri, 'assets/image/exercises/squat.png');
    final custom = imported.plan.days.single.blocks.last.exercises.single;
    expect(custom.mediaSource, ExerciseMediaSource.gallery);
    expect(custom.mediaKind, ExerciseMediaKind.gif);
    expect(File(custom.mediaUri!).existsSync(), isTrue);
    expect(imported.issues, isEmpty);
  });

  test('missing media file still imports the exercise', () async {
    const json = '''
{
  "name": "Partial",
  "basic-plan": [{
    "name": "Day 1",
    "exercises": [{
      "type": "single",
      "exercise": {
        "title": "mystery",
        "sets": 3,
        "times": 8,
        "media": { "role": "file", "path": "media/missing.gif", "kind": "gif" }
      }
    }]
  }]
}
''';
    final imported = await const PlanPackageImporter().importBytes(
      utf8.encode(json),
      fileName: 'partial.json',
    );
    expect(imported.plan.title, 'Partial');
    expect(imported.plan.days.single.blocks, hasLength(1));
    expect(
      imported.issues.map((i) => i.message).join('\n'),
      contains('Couldn’t load the mystery clip'),
    );
  });
}
