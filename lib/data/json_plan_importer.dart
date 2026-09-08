import 'dart:convert';

import '../common/exercise_asset_catalog.dart';
import '../domain/common_section_migration.dart';
import '../domain/models/models.dart';
import '../domain/new_id.dart';
import '../domain/plan_catalog.dart';
import '../domain/plan_import_issue.dart';
import '../domain/plan_validation.dart';

/// Thrown when a file cannot be turned into even a salvageable [WorkoutPlan].
///
/// [message] is safe to show in the UI.
class PlanImportException implements Exception {
  const PlanImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parsed import plus titles that used to be `common-plan` sections.
class JsonPlanImport {
  const JsonPlanImport({
    required this.plan,
    this.convertedCommonSectionTitles = const [],
    this.issues = const [],
    this.usedJsonPath,
  });

  final WorkoutPlan plan;
  final List<String> convertedCommonSectionTitles;
  final List<PlanImportIssue> issues;
  final String? usedJsonPath;

  bool get hasIssues => issues.isNotEmpty;
}

/// Maps v1 import JSON (`name`, `basic-plan`, `common-plan`) onto [WorkoutPlan].
///
/// Recoverable problems become [JsonPlanImport.issues] instead of aborting.
class JsonPlanImporter {
  const JsonPlanImporter({
    this.newId = defaultNewId,
    this.clock,
  });

  final String Function() newId;
  final DateTime Function()? clock;

  /// Parses [source] into a plan. Starter templates use this (active status).
  WorkoutPlan import(
    String source, {
    PlanStatus status = PlanStatus.active,
  }) =>
      importDetailed(source, status: status).plan;

  JsonPlanImport importDetailed(
    String source, {
    PlanStatus status = PlanStatus.draft,
  }) {
    final session = _ImportSession(
      newId: newId,
      clock: clock ?? DateTime.now,
      status: status,
    );
    return session.run(source);
  }
}

class _ImportSession {
  _ImportSession({
    required this.newId,
    required this.clock,
    required this.status,
  });

  final String Function() newId;
  final DateTime Function() clock;
  final PlanStatus status;
  final issues = <PlanImportIssue>[];

  JsonPlanImport run(String source) {
    final decoded = _decode(source);
    if (decoded == null) {
      throw const PlanImportException(
        'This file is not a plan package or JSON we can read.',
      );
    }

    final root = _asObjectOrNull(decoded, 'This file');
    if (root == null) {
      issues.add(
        const PlanImportIssue(
          code: 'not-object',
          message:
              'This file had syntax issues. Check the plan before creating it.',
          stepKey: detailsStepKey,
        ),
      );
      return _finish(title: '', days: [_emptyDay()], common: const []);
    }

    final title = _optionalString(root['name']);
    if (title.isEmpty) {
      issues.add(
        const PlanImportIssue(
          code: 'missing-name',
          message: 'This plan needs a name.',
          stepKey: detailsStepKey,
        ),
      );
    }

    final days = <PlanDay>[];
    final daysJson = root['basic-plan'];
    if (daysJson == null) {
      issues.add(
        const PlanImportIssue(
          code: 'missing-days',
          message: 'No days found. Add at least one exercise.',
          stepKey: detailsStepKey,
        ),
      );
    } else {
      final list = _asListOrNull(daysJson, 'basic-plan');
      if (list == null) {
        issues.add(
          const PlanImportIssue(
            code: 'missing-days',
            message: 'No days found. Add at least one exercise.',
            stepKey: detailsStepKey,
          ),
        );
      } else if (list.isEmpty) {
        issues.add(
          const PlanImportIssue(
            code: 'empty-days',
            message: 'No days found. Add at least one exercise.',
            stepKey: detailsStepKey,
          ),
        );
      } else {
        for (var i = 0; i < list.length; i++) {
          days.add(_parseDay(list[i], index: i));
        }
      }
    }
    if (days.isEmpty) days.add(_emptyDay());

    final commonSections = <CommonSection>[];
    final commonJson = root['common-plan'];
    if (commonJson != null) {
      final sections = _asListOrNull(commonJson, 'common-plan');
      if (sections == null) {
        issues.add(
          const PlanImportIssue(
            code: 'common-plan',
            message: 'Former extra sections could not be read and were skipped.',
            stepKey: detailsStepKey,
          ),
        );
      } else {
        for (var i = 0; i < sections.length; i++) {
          final section = _parseCommonSection(sections[i], index: i);
          if (section != null) commonSections.add(section);
        }
      }
    }

    return _finish(
      title: title,
      description: _optionalString(root['description']),
      goalIds: canonicalizeGoalIds(_stringList(root['goals'])),
      days: days,
      common: commonSections,
    );
  }

  JsonPlanImport _finish({
    required String title,
    String description = '',
    List<String> goalIds = const [],
    required List<PlanDay> days,
    required List<CommonSection> common,
  }) {
    final convertedTitles = [for (final section in common) section.title];
    if (convertedTitles.isNotEmpty) {
      issues.add(
        PlanImportIssue(
          code: 'common-plan',
          message:
              'Former common sections are now regular days: ${convertedTitles.join(', ')}.',
          stepKey: reviewStepKey,
        ),
      );
    }
    final now = clock().toUtc();
    return JsonPlanImport(
      plan: WorkoutPlan.create(
        title: title,
        description: description,
        goalIds: goalIds,
        source: PlanSource.imported,
        status: status,
        createdAt: now,
        updatedAt: now,
        days: migrateCommonSectionsToDays(days: days, sections: common),
      ),
      convertedCommonSectionTitles: convertedTitles,
      issues: List.unmodifiable(issues),
    );
  }

  Object? _decode(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      final salvaged = stripTrailingCommas(source);
      if (salvaged != source) {
        try {
          final decoded = jsonDecode(salvaged);
          issues.add(
            const PlanImportIssue(
              code: 'syntax',
              message:
                  'This file had syntax issues. Check the plan before creating it.',
              stepKey: detailsStepKey,
            ),
          );
          return decoded;
        } on FormatException {
          // continue
        }
      }
      final trimmed = source.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        issues.add(
          const PlanImportIssue(
            code: 'syntax',
            message:
                'This file had syntax issues. Check the plan before creating it.',
            stepKey: detailsStepKey,
          ),
        );
        return <String, dynamic>{};
      }
      return null;
    }
  }

  PlanDay _emptyDay() => PlanDay.create(dayId: newId(), title: 'Day 1');

  PlanDay _parseDay(Object? raw, {required int index}) {
    final where = 'Day ${index + 1}';
    final json = _asObjectOrNull(raw, where);
    if (json == null) {
      issues.add(
        PlanImportIssue(
          code: 'bad-day',
          message: '$where could not be read and was replaced with an empty day.',
          stepKey: detailsStepKey,
        ),
      );
      return PlanDay.create(dayId: newId(), title: where);
    }
    var title = _optionalString(json['name']);
    if (title.isEmpty) {
      title = where;
      issues.add(
        PlanImportIssue(
          code: 'day-name',
          message: '$where needs a name.',
        ),
      );
    }
    final dayId = newId();
    final exercisesRaw = json['exercises'];
    List<ExerciseBlock> blocks;
    if (exercisesRaw == null) {
      issues.add(
        PlanImportIssue(
          code: 'day-exercises',
          message: '$where ("$title") needs an exercises list.',
          stepKey: dayId,
        ),
      );
      blocks = const [];
    } else {
      final exercises = _asListOrNull(
        exercisesRaw,
        '$where ("$title") exercises',
      );
      if (exercises == null) {
        issues.add(
          PlanImportIssue(
            code: 'day-exercises',
            message: '$where ("$title") needs an exercises list.',
            stepKey: dayId,
          ),
        );
        blocks = const [];
      } else {
        blocks = _parseBlocks(exercises, where: 'Day "$title"', dayId: dayId);
      }
    }
    return PlanDay.create(
      dayId: dayId,
      title: title,
      summary: _optionalString(json['summary']),
      blocks: blocks,
    );
  }

  CommonSection? _parseCommonSection(Object? raw, {required int index}) {
    final where = 'Common section ${index + 1}';
    final json = _asObjectOrNull(raw, where);
    if (json == null) {
      issues.add(
        PlanImportIssue(
          code: 'common-plan',
          message: '$where could not be read and was skipped.',
          stepKey: reviewStepKey,
        ),
      );
      return null;
    }
    var title = _optionalString(json['name']);
    if (title.isEmpty) {
      title = where;
      issues.add(
        PlanImportIssue(
          code: 'common-plan',
          message: '$where needs a name.',
          stepKey: reviewStepKey,
        ),
      );
    }
    final exercisesRaw = json['exercises'];
    if (exercisesRaw == null) {
      issues.add(
        PlanImportIssue(
          code: 'common-plan',
          message: '$where ("$title") needs an exercises list.',
          stepKey: reviewStepKey,
        ),
      );
      return CommonSection.create(sectionId: newId(), title: title);
    }
    final exercises = _asListOrNull(exercisesRaw, '$where ("$title") exercises');
    if (exercises == null) {
      issues.add(
        PlanImportIssue(
          code: 'common-plan',
          message: '$where ("$title") needs an exercises list.',
          stepKey: reviewStepKey,
        ),
      );
      return CommonSection.create(sectionId: newId(), title: title);
    }
    return CommonSection.create(
      sectionId: newId(),
      title: title,
      blocks: _parseBlocks(exercises, where: 'Section "$title"', dayId: null),
    );
  }

  List<ExerciseBlock> _parseBlocks(
    List<dynamic> exercises, {
    required String where,
    required String? dayId,
  }) {
    final blocks = <ExerciseBlock>[];
    for (var i = 0; i < exercises.length; i++) {
      final location = '$where, exercise ${i + 1}';
      final json = _asObjectOrNull(exercises[i], location);
      if (json == null) {
        issues.add(
          PlanImportIssue(
            code: 'unknown-block',
            message: 'Skipped an exercise we could not read on ${where.toLowerCase()}.',
            stepKey: dayId,
          ),
        );
        continue;
      }
      final type = _optionalString(json['type']);
      if (type == 'single') {
        final block = _parseSingle(json['exercise'], location, dayId);
        if (block != null) blocks.add(block);
      } else if (type == 'super-set') {
        final block = _parseSuperset(json['exercise'], location, dayId);
        if (block != null) blocks.add(block);
      } else {
        issues.add(
          PlanImportIssue(
            code: 'unknown-block',
            message: type.isEmpty
                ? 'Skipped an exercise we could not read on ${where.toLowerCase()}.'
                : 'Skipped an exercise we could not read on ${where.toLowerCase()}.',
            stepKey: dayId,
          ),
        );
      }
    }
    return blocks;
  }

  ExerciseBlock? _parseSingle(Object? raw, String location, String? dayId) {
    final json = _asObjectOrNull(raw, '$location (single)');
    if (json == null) {
      issues.add(
        PlanImportIssue(
          code: 'unknown-block',
          message: '$location (single) needs an exercise object.',
          stepKey: dayId,
        ),
      );
      return null;
    }
    final exercise = _parsePrescription(json, location, dayId);
    if (exercise == null) return null;
    return ExerciseBlock.create(
      blockId: newId(),
      kind: BlockKind.single,
      exercises: [exercise],
    );
  }

  ExerciseBlock? _parseSuperset(Object? raw, String location, String? dayId) {
    final items = _asListOrNull(raw, '$location (super-set)');
    if (items == null) {
      issues.add(
        PlanImportIssue(
          code: 'unknown-block',
          message: '$location (super-set) needs a list of exercises.',
          stepKey: dayId,
        ),
      );
      return null;
    }
    final exercises = <ExercisePrescription>[];
    for (var i = 0; i < items.length; i++) {
      final json = _asObjectOrNull(items[i], '$location, movement ${i + 1}');
      if (json == null) continue;
      final parsed = _parsePrescription(
        json,
        '$location, movement ${i + 1}',
        dayId,
      );
      if (parsed != null) exercises.add(parsed);
    }
    if (exercises.length < 2) {
      issues.add(
        PlanImportIssue(
          code: 'superset',
          message: '$location is a super-set and needs at least two exercises.',
          stepKey: dayId,
        ),
      );
      if (exercises.length == 1) {
        return ExerciseBlock.create(
          blockId: newId(),
          kind: BlockKind.single,
          exercises: exercises,
        );
      }
      return null;
    }
    return ExerciseBlock.create(
      blockId: newId(),
      kind: BlockKind.superset,
      exercises: exercises,
    );
  }

  ExercisePrescription? _parsePrescription(
    Map<String, dynamic> json,
    String location,
    String? dayId,
  ) {
    final title = _optionalString(json['title']);
    if (title.isEmpty) {
      issues.add(
        PlanImportIssue(
          code: 'exercise-title',
          message: '$location needs an exercise title.',
          stepKey: dayId,
        ),
      );
      return null;
    }

    var sets = _asInt(json['sets'], '$location ("$title") sets');
    if (sets == null || sets < 1) {
      issues.add(
        PlanImportIssue(
          code: 'prescription',
          message: '$location ("$title") needs at least 1 set.',
          stepKey: dayId,
          exerciseTitle: title,
        ),
      );
      sets = 1;
    }

    var reps = _asInt(json['times'], '$location ("$title") times');
    var duration = _asInt(json['duration'], '$location ("$title") duration');
    if (reps != null && reps < 1) {
      issues.add(
        PlanImportIssue(
          code: 'prescription',
          message: '$location ("$title") times must be at least 1.',
          stepKey: dayId,
          exerciseTitle: title,
        ),
      );
      reps = null;
    }
    if (duration != null && duration < 1) {
      issues.add(
        PlanImportIssue(
          code: 'prescription',
          message: '$location ("$title") duration must be at least 1 second.',
          stepKey: dayId,
          exerciseTitle: title,
        ),
      );
      duration = null;
    }
    if (reps != null && duration != null) {
      issues.add(
        PlanImportIssue(
          code: 'prescription',
          message:
              '$location ("$title") must have either times or duration, not both.',
          stepKey: dayId,
          exerciseTitle: title,
        ),
      );
      reps = null;
      duration = null;
    }
    if (reps == null && duration == null) {
      issues.add(
        PlanImportIssue(
          code: 'prescription',
          message: '$location ("$title") needs times (reps) or duration (seconds).',
          stepKey: dayId,
          exerciseTitle: title,
        ),
      );
    }

    final rawAreas = json['target-areas'];
    final targetAreaIds = rawAreas == null
        ? catalogTargetAreaIdsForTitle(title)
        : canonicalizeTargetAreaIds(_stringList(rawAreas));

    final match = matchExerciseAsset(title);
    final catalogId = _optionalString(json['catalog-exercise-id']).isNotEmpty
        ? _optionalString(json['catalog-exercise-id'])
        : _optionalString(json['catalogExerciseId']).isNotEmpty
            ? _optionalString(json['catalogExerciseId'])
            : match?.id;

    final media = _resolveMedia(
      json: json,
      title: title,
      catalogId: catalogId,
      match: match,
      dayId: dayId,
    );

    return ExercisePrescription.create(
      prescriptionId: newId(),
      title: title,
      prescribedSets: sets,
      prescribedReps: reps,
      prescribedDurationSeconds: duration,
      targetAreaIds: targetAreaIds,
      catalogExerciseId: catalogId,
      svgPath: media.svgPath,
      mediaUri: media.uri,
      mediaSource: media.source,
      mediaKind: media.kind,
    );
  }

  ({
    String? uri,
    String? svgPath,
    ExerciseMediaSource source,
    ExerciseMediaKind kind,
  }) _resolveMedia({
    required Map<String, dynamic> json,
    required String title,
    required String? catalogId,
    required ExerciseAssetEntry? match,
    required String? dayId,
  }) {
    final mediaJson = json['media'];
    if (mediaJson is Map) {
      final media = Map<String, dynamic>.from(mediaJson);
      final role = _optionalString(media['role']);
      final kindName = _optionalString(media['kind']);
      if (role == 'url') {
        final url = _optionalNonEmpty(media['url']) ??
            _optionalNonEmpty(media['path']);
        if (url != null) {
          return (
            uri: url,
            svgPath: null,
            source: ExerciseMediaSource.network,
            kind: _mediaKind(kindName, url),
          );
        }
      }
      if (role == 'file') {
        final path = _optionalNonEmpty(media['path']);
        if (path == null) {
          issues.add(
            PlanImportIssue(
              code: 'missing-media',
              message:
                  'Couldn’t load the $title clip. Pick a photo, GIF, or video.',
              stepKey: dayId,
              exerciseTitle: title,
            ),
          );
        } else {
          return (
            uri: path,
            svgPath: null,
            source: ExerciseMediaSource.gallery,
            kind: _mediaKind(kindName, path),
          );
        }
      }
      if (role == 'bundled') {
        final id = _optionalNonEmpty(media['id']) ?? catalogId;
        final bundled = bundledAssetById(id) ?? match;
        if (bundled == null) {
          issues.add(
            PlanImportIssue(
              code: 'unknown-bundled',
              message:
                  '3 exercises will use default icons until you pick media.',
              stepKey: dayId,
              exerciseTitle: title,
            ),
          );
        } else {
          return (
            uri: bundled.assetPath,
            svgPath: bundled.assetPath,
            source: ExerciseMediaSource.asset,
            kind: _mediaKind(kindName, bundled.assetPath),
          );
        }
      }
    }

    final mediaUri = _optionalNonEmpty(json['mediaUri']) ??
        _optionalNonEmpty(json['svgPath']) ??
        match?.assetPath;
    final mediaSourceName = _optionalString(json['mediaSource']);
    final mediaKindName = _optionalString(json['mediaKind']);
    if (mediaUri == null) {
      return (
        uri: null,
        svgPath: null,
        source: ExerciseMediaSource.none,
        kind: ExerciseMediaKind.unknown,
      );
    }
    return (
      uri: mediaUri,
      svgPath: mediaUri,
      source: _mediaSource(mediaSourceName),
      kind: _mediaKind(mediaKindName, mediaUri),
    );
  }

  Map<String, dynamic>? _asObjectOrNull(Object? value, String what) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    issues.add(
      PlanImportIssue(
        code: 'shape',
        message: '$what is not a JSON object.',
        stepKey: detailsStepKey,
      ),
    );
    return null;
  }

  List<dynamic>? _asListOrNull(Object? value, String what) {
    if (value is List) return value;
    issues.add(
      PlanImportIssue(
        code: 'shape',
        message: '$what is not a JSON array.',
        stepKey: detailsStepKey,
      ),
    );
    return null;
  }

  int? _asInt(Object? value, String what) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) {
      return value.toInt();
    }
    issues.add(
      PlanImportIssue(
        code: 'shape',
        message: '$what must be a whole number.',
        stepKey: detailsStepKey,
      ),
    );
    return null;
  }
}

String defaultNewId() => newId();

/// Removes trailing commas before `}` or `]` so sloppy JSON can still import.
String stripTrailingCommas(String source) {
  return source.replaceAllMapped(
    RegExp(r',(\s*[}\]])'),
    (match) => match.group(1)!,
  );
}

String _optionalString(Object? value) {
  if (value is! String) return '';
  return value.trim();
}

String? _optionalNonEmpty(Object? value) {
  final text = _optionalString(value);
  return text.isEmpty ? null : text;
}

ExerciseMediaSource _mediaSource(String raw) {
  for (final value in ExerciseMediaSource.values) {
    if (value.name == raw) return value;
  }
  return ExerciseMediaSource.asset;
}

ExerciseMediaKind _mediaKind(String raw, String path) {
  for (final value in ExerciseMediaKind.values) {
    if (value.name == raw && value != ExerciseMediaKind.unknown) return value;
  }
  return mediaKindForPath(path);
}

List<String> _stringList(Object? value) {
  if (value == null) return const [];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}

ExerciseMediaKind mediaKindForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.svg')) return ExerciseMediaKind.svg;
  if (lower.endsWith('.gif')) return ExerciseMediaKind.gif;
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv')) {
    return ExerciseMediaKind.video;
  }
  return ExerciseMediaKind.image;
}
