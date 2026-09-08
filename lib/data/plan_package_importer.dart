import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../common/exercise_asset_catalog.dart';
import '../domain/models/models.dart';
import '../domain/plan_import_issue.dart';
import '../domain/plan_validation.dart';
import 'exercise_media_store.dart';
import 'json_plan_importer.dart';
import 'plan_package_format.dart';

/// Reads `.gymplan` / `.zip` / `.json` bytes into a salvageable plan.
class PlanPackageImporter {
  const PlanPackageImporter({
    this.jsonImporter = const JsonPlanImporter(),
    this.mediaStore,
  });

  final JsonPlanImporter jsonImporter;
  final ExerciseMediaStore? mediaStore;

  Future<JsonPlanImport> importBytes(
    List<int> bytes, {
    String fileName = 'plan.json',
  }) async {
    if (bytes.isEmpty) {
      throw const PlanImportException(
        'Could not read that file. Try another plan package or JSON file.',
      );
    }

    if (looksLikeZip(bytes) || _isPackageName(fileName)) {
      return _importZip(bytes, fileName: fileName);
    }

    final text = _decodeUtf8(bytes);
    if (text == null) {
      throw const PlanImportException(
        'This file is not a plan package or JSON we can read.',
      );
    }
    final imported = jsonImporter.importDetailed(text);
    return _finalizeMedia(imported);
  }

  Future<JsonPlanImport> _importZip(List<int> bytes, {required String fileName}) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(Uint8List.fromList(bytes), verify: false);
    } catch (_) {
      final text = _decodeUtf8(bytes);
      if (text != null) {
        return _finalizeMedia(jsonImporter.importDetailed(text));
      }
      throw const PlanImportException(
        'This file is not a plan package or JSON we can read.',
      );
    }

    final files = <String, ArchiveFile>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      files[_normalizeZipPath(file.name)] = file;
    }

    final issues = <PlanImportIssue>[];
    var formatVersion = PlanPackageFormat.formatVersion;
    final manifestFile = _find(files, PlanPackageFormat.manifestName);
    if (manifestFile != null) {
      try {
        final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>));
        if (manifest is Map && manifest['formatVersion'] is num) {
          formatVersion = (manifest['formatVersion'] as num).toInt();
        }
      } catch (_) {
        issues.add(
          const PlanImportIssue(
            code: 'manifest',
            message:
                'This file had syntax issues. Check the plan before creating it.',
            stepKey: detailsStepKey,
          ),
        );
      }
    }
    if (formatVersion > PlanPackageFormat.formatVersion) {
      issues.add(
        const PlanImportIssue(
          code: 'format-version',
          message:
              'This package is newer than the app. Some fields may be missing.',
          stepKey: reviewStepKey,
        ),
      );
    }

    final jsonFile = files[PlanPackageFormat.planJsonName] ??
        _firstJson(files);
    if (jsonFile == null) {
      issues.add(
        const PlanImportIssue(
          code: 'missing-plan-json',
          message:
              'The plan file was damaged. Media is on the draft where we could match it.',
          stepKey: detailsStepKey,
        ),
      );
      final empty = jsonImporter.importDetailed('{}');
      return JsonPlanImport(
        plan: empty.plan,
        issues: [...issues, ...empty.issues],
      );
    }

    final usedPath = _normalizeZipPath(jsonFile.name);
    if (usedPath != PlanPackageFormat.planJsonName) {
      issues.add(
        PlanImportIssue(
          code: 'alt-json',
          message: 'Used $usedPath as the plan file.',
          stepKey: reviewStepKey,
        ),
      );
    }

    final text = utf8.decode(jsonFile.content as List<int>);
    var imported = jsonImporter.importDetailed(text);
    imported = JsonPlanImport(
      plan: imported.plan,
      convertedCommonSectionTitles: imported.convertedCommonSectionTitles,
      issues: [...issues, ...imported.issues],
      usedJsonPath: usedPath,
    );
    return _finalizeMedia(imported, zipFiles: files);
  }

  Future<JsonPlanImport> _finalizeMedia(
    JsonPlanImport imported, {
    Map<String, ArchiveFile>? zipFiles,
  }) async {
    final extra = <PlanImportIssue>[];
    var unknownBundled = 0;
    for (final day in imported.plan.days) {
      for (final block in day.blocks) {
        for (final exercise in block.exercises) {
          if (exercise.mediaSource == ExerciseMediaSource.gallery) {
            final path = exercise.mediaUri?.trim();
            if (path == null || path.isEmpty) {
              _fallbackMedia(exercise, extra, day.dayId);
              continue;
            }
            if (path.startsWith('/') ||
                (path.length > 2 && path[1] == ':')) {
              // Absolute path from another phone — do not keep.
              extra.add(
                PlanImportIssue(
                  code: 'missing-media',
                  message:
                      'Couldn’t load the ${exercise.title} clip. Pick a photo, GIF, or video.',
                  stepKey: day.dayId,
                  exerciseTitle: exercise.title,
                ),
              );
              _fallbackMedia(exercise, extra, day.dayId, alreadyIssued: true);
              continue;
            }
            final packed = zipFiles?[_normalizeZipPath(path)] ??
                zipFiles?[_normalizeZipPath(
                  '${PlanPackageFormat.mediaFolder}/${p.basename(path)}',
                )];
            if (packed == null) {
              extra.add(
                PlanImportIssue(
                  code: 'missing-media',
                  message:
                      'Couldn’t load the ${exercise.title} clip. Pick a photo, GIF, or video.',
                  stepKey: day.dayId,
                  exerciseTitle: exercise.title,
                ),
              );
              _fallbackMedia(exercise, extra, day.dayId, alreadyIssued: true);
              continue;
            }
            final raw = packed.content as List<int>;
            if (raw.length > PlanPackageFormat.maxMediaBytes) {
              extra.add(
                PlanImportIssue(
                  code: 'missing-media',
                  message:
                      'Couldn’t load the ${exercise.title} clip. Pick a photo, GIF, or video.',
                  stepKey: day.dayId,
                  exerciseTitle: exercise.title,
                ),
              );
              _fallbackMedia(exercise, extra, day.dayId, alreadyIssued: true);
              continue;
            }
            final store = mediaStore;
            if (store == null) {
              extra.add(
                PlanImportIssue(
                  code: 'missing-media',
                  message:
                      'Couldn’t load the ${exercise.title} clip. Pick a photo, GIF, or video.',
                  stepKey: day.dayId,
                  exerciseTitle: exercise.title,
                ),
              );
              _fallbackMedia(exercise, extra, day.dayId, alreadyIssued: true);
              continue;
            }
            final local = await store.persistBytes(raw, p.extension(path));
            exercise.mediaUri = local;
            exercise.mediaSource = ExerciseMediaSource.gallery;
            exercise.svgPath = null;
          } else if (exercise.mediaSource == ExerciseMediaSource.asset) {
            // Count unresolved bundled ids already flagged.
          }
        }
      }
    }
    for (final issue in imported.issues) {
      if (issue.code == 'unknown-bundled') unknownBundled += 1;
    }
    final collapsed = [
      for (final issue in imported.issues)
        if (issue.code != 'unknown-bundled') issue,
      ...extra,
    ];
    if (unknownBundled > 0) {
      collapsed.add(
        PlanImportIssue(
          code: 'unknown-bundled',
          message:
              '$unknownBundled ${unknownBundled == 1 ? 'exercise' : 'exercises'} will use default icons until you pick media.',
          stepKey: reviewStepKey,
        ),
      );
    }
    return JsonPlanImport(
      plan: imported.plan,
      convertedCommonSectionTitles: imported.convertedCommonSectionTitles,
      issues: collapsed,
      usedJsonPath: imported.usedJsonPath,
    );
  }

  void _fallbackMedia(
    ExercisePrescription exercise,
    List<PlanImportIssue> extra,
    String dayId, {
    bool alreadyIssued = false,
  }) {
    final match = matchExerciseAsset(exercise.title);
    if (match != null) {
      exercise.mediaUri = match.assetPath;
      exercise.svgPath = match.assetPath;
      exercise.mediaSource = ExerciseMediaSource.asset;
      exercise.mediaKind = mediaKindForPath(match.assetPath);
      exercise.catalogExerciseId ??= match.id;
      return;
    }
    exercise.mediaUri = null;
    exercise.svgPath = null;
    exercise.mediaSource = ExerciseMediaSource.none;
    exercise.mediaKind = ExerciseMediaKind.unknown;
    if (!alreadyIssued) {
      extra.add(
        PlanImportIssue(
          code: 'missing-media',
          message:
              'Couldn’t load the ${exercise.title} clip. Pick a photo, GIF, or video.',
          stepKey: dayId,
          exerciseTitle: exercise.title,
        ),
      );
    }
  }

  ArchiveFile? _find(Map<String, ArchiveFile> files, String name) => files[name];

  ArchiveFile? _firstJson(Map<String, ArchiveFile> files) {
    for (final entry in files.entries) {
      if (entry.key.endsWith('.json') &&
          entry.key != PlanPackageFormat.manifestName) {
        return entry.value;
      }
    }
    return null;
  }

  String _normalizeZipPath(String name) =>
      name.replaceAll('\\', '/').replaceFirst(RegExp(r'^/'), '');

  bool _isPackageName(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.${PlanPackageFormat.extension}') ||
        lower.endsWith('.zip');
  }

  String? _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }
}
