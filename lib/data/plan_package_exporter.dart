import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../common/exercise_asset_catalog.dart';
import '../domain/models/models.dart';
import 'jpeg_exif.dart';
import 'plan_package_format.dart';

class PlanPackageBuild {
  const PlanPackageBuild({
    required this.bytes,
    required this.fileName,
    this.warnings = const [],
  });

  final Uint8List bytes;
  final String fileName;
  final List<String> warnings;
}

/// Writes a plan as `.gymplan` (zip) or lite JSON.
class PlanPackageExporter {
  const PlanPackageExporter({this.clock});

  final DateTime Function()? clock;

  PlanPackageBuild exportJson(WorkoutPlan plan) {
    final encoded = const JsonEncoder.withIndent('  ').convert(
      encodePlanJson(plan),
    );
    return PlanPackageBuild(
      bytes: Uint8List.fromList(utf8.encode(encoded)),
      fileName: '${_fileStem(plan)}.json',
    );
  }

  Future<PlanPackageBuild> exportZip(
    WorkoutPlan plan, {
    bool lite = false,
  }) async {
    if (lite) return exportJson(plan);

    final warnings = <String>[];
    final mediaFiles = <String, List<int>>{};
    final pathByHash = <String, String>{};
    final packedByPrescription = <String, String>{};

    for (final exercise in _allExercises(plan)) {
      if (exercise.mediaSource != ExerciseMediaSource.gallery) continue;
      final uri = exercise.mediaUri?.trim();
      if (uri == null || uri.isEmpty || uri.startsWith('http')) continue;
      final file = File(uri);
      if (!file.existsSync()) {
        warnings.add(
          'Couldn’t pack the ${exercise.title} clip; file is missing.',
        );
        continue;
      }
      var bytes = await file.readAsBytes();
      if (bytes.length > PlanPackageFormat.maxMediaBytes) {
        warnings.add(
          'Skipped ${exercise.title}: the file is larger than '
          '${PlanPackageFormat.maxMediaBytes ~/ (1024 * 1024)} MB.',
        );
        continue;
      }
      final lower = uri.toLowerCase();
      if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        bytes = stripJpegExif(bytes);
      }
      final hash = sha256.convert(bytes).toString().substring(0, 16);
      final existing = pathByHash[hash];
      if (existing != null) {
        packedByPrescription[exercise.prescriptionId] = existing;
        continue;
      }
      final ext = p.extension(uri).toLowerCase();
      final relative = '${PlanPackageFormat.mediaFolder}/$hash$ext';
      mediaFiles[relative] = bytes;
      pathByHash[hash] = relative;
      packedByPrescription[exercise.prescriptionId] = relative;
    }

    final archive = Archive();
    final now = (clock ?? DateTime.now)().toUtc().toIso8601String();
    final manifest = utf8.encode(
      jsonEncode({
        'formatVersion': PlanPackageFormat.formatVersion,
        'createdByApp': PlanPackageFormat.createdByApp,
        'createdAt': now,
        'planUid': plan.uuid,
      }),
    );
    archive.addFile(
      ArchiveFile(PlanPackageFormat.manifestName, manifest.length, manifest),
    );
    final planJson = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(
        encodePlanJson(plan, packedFiles: packedByPrescription),
      ),
    );
    archive.addFile(
      ArchiveFile(PlanPackageFormat.planJsonName, planJson.length, planJson),
    );
    for (final entry in mediaFiles.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final zip = ZipEncoder().encode(archive);
    return PlanPackageBuild(
      bytes: Uint8List.fromList(zip),
      fileName: '${_fileStem(plan)}.${PlanPackageFormat.extension}',
      warnings: warnings,
    );
  }
}

Map<String, dynamic> encodePlanJson(
  WorkoutPlan plan, {
  Map<String, String> packedFiles = const {},
}) {
  return {
    'name': plan.title,
    'description': plan.description,
    'goals': plan.goalIds,
    'days': plan.days.length,
    'basic-plan': [
      for (final day in plan.days) _encodeDay(day, packedFiles),
    ],
  };
}

Map<String, dynamic> _encodeDay(
  PlanDay day,
  Map<String, String> packedFiles,
) {
  return {
    'name': day.title,
    if (day.summary.trim().isNotEmpty) 'summary': day.summary,
    'exercises': [
      for (final block in day.blocks) _encodeBlock(block, packedFiles),
    ],
  };
}

Map<String, dynamic> _encodeBlock(
  ExerciseBlock block,
  Map<String, String> packedFiles,
) {
  if (block.kind == BlockKind.superset) {
    return {
      'type': 'super-set',
      'exercise': [
        for (final exercise in block.exercises)
          _encodeExercise(exercise, packedFiles),
      ],
    };
  }
  return {
    'type': 'single',
    'exercise': block.exercises.isEmpty
        ? <String, dynamic>{}
        : _encodeExercise(block.exercises.first, packedFiles),
  };
}

Map<String, dynamic> _encodeExercise(
  ExercisePrescription exercise,
  Map<String, String> packedFiles,
) {
  final json = <String, dynamic>{
    'title': exercise.title,
    'sets': exercise.prescribedSets,
    'times': exercise.prescribedReps,
    'duration': exercise.prescribedDurationSeconds,
  };
  if (exercise.targetAreaIds.isNotEmpty) {
    json['target-areas'] = exercise.targetAreaIds;
  }
  if (exercise.catalogExerciseId != null &&
      exercise.catalogExerciseId!.trim().isNotEmpty) {
    json['catalog-exercise-id'] = exercise.catalogExerciseId;
  }
  final media = _encodeMedia(exercise, packedFiles);
  if (media != null) json['media'] = media;
  return json;
}

Map<String, dynamic>? _encodeMedia(
  ExercisePrescription exercise,
  Map<String, String> packedFiles,
) {
  if (exercise.mediaSource == ExerciseMediaSource.network) {
    final url = exercise.mediaUri?.trim();
    if (url == null || url.isEmpty) return null;
    return {
      'role': 'url',
      'url': url,
      'kind': exercise.mediaKind.name,
    };
  }
  if (exercise.mediaSource == ExerciseMediaSource.gallery) {
    final packed = packedFiles[exercise.prescriptionId];
    if (packed == null || packed.isEmpty) return null;
    return {
      'role': 'file',
      'path': packed,
      'kind': exercise.mediaKind.name,
    };
  }
  final bundled = bundledAssetById(exercise.catalogExerciseId) ??
      bundledAssetByPath(exercise.mediaUri) ??
      matchExerciseAsset(exercise.title);
  if (bundled == null) return null;
  return {
    'role': 'bundled',
    'id': bundled.id,
    'kind': 'image',
  };
}

Iterable<ExercisePrescription> _allExercises(WorkoutPlan plan) sync* {
  for (final day in plan.days) {
    for (final block in day.blocks) {
      yield* block.exercises;
    }
  }
}

String _fileStem(WorkoutPlan plan) {
  final raw = plan.title.trim().isEmpty ? 'untitled-plan' : plan.title.trim();
  final slug = raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'untitled-plan' : slug;
}
