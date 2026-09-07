import 'dart:convert';

import '../common/exercise_asset_catalog.dart';
import '../domain/common_section_migration.dart';
import '../domain/models/models.dart';
import '../domain/new_id.dart';
import '../domain/plan_catalog.dart';

/// Thrown when a JSON file cannot be turned into a [WorkoutPlan].
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
  });

  final WorkoutPlan plan;
  final List<String> convertedCommonSectionTitles;
}

/// Maps v1 import JSON (`name`, `basic-plan`, `common-plan`) onto [WorkoutPlan].
class JsonPlanImporter {
  const JsonPlanImporter({
    this.newId = defaultNewId,
    this.clock,
  });

  final String Function() newId;
  final DateTime Function()? clock;

  /// Parses [source] into a new imported plan. Nested ids are generated here.
  WorkoutPlan import(String source) => importDetailed(source).plan;

  JsonPlanImport importDetailed(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const PlanImportException(
        'This file is not valid JSON. Remove trailing commas or other '
        'syntax errors and try again.',
      );
    }

    final root = _asObject(decoded, 'This file');
    final title = _requiredString(root['name'], 'This plan needs a name.');
    final daysJson = _asList(
      root['basic-plan'],
      'This plan is missing a basic-plan list of days.',
    );
    if (daysJson.isEmpty) {
      throw const PlanImportException('This plan has no days in basic-plan.');
    }

    final days = <PlanDay>[];
    for (var i = 0; i < daysJson.length; i++) {
      days.add(_parseDay(daysJson[i], index: i));
    }

    final commonJson = root['common-plan'];
    final commonSections = <CommonSection>[];
    if (commonJson != null) {
      final sections = _asList(commonJson, 'common-plan');
      for (var i = 0; i < sections.length; i++) {
        commonSections.add(_parseCommonSection(sections[i], index: i));
      }
    }

    final convertedTitles = [
      for (final section in commonSections) section.title,
    ];
    final now = (clock ?? DateTime.now)().toUtc();
    return JsonPlanImport(
      plan: WorkoutPlan.create(
        title: title,
        description: _optionalString(root['description']),
        goalIds: canonicalizeGoalIds(_stringList(root['goals'])),
        source: PlanSource.imported,
        status: PlanStatus.active,
        createdAt: now,
        updatedAt: now,
        days: migrateCommonSectionsToDays(
          days: days,
          sections: commonSections,
        ),
      ),
      convertedCommonSectionTitles: convertedTitles,
    );
  }

  PlanDay _parseDay(Object? raw, {required int index}) {
    final where = 'Day ${index + 1}';
    final json = _asObject(raw, where);
    final title = _requiredString(json['name'], '$where needs a name.');
    final exercises = _asList(
      json['exercises'],
      '$where ("$title") needs an exercises list.',
    );
    return PlanDay.create(
      dayId: newId(),
      title: title,
      blocks: _parseBlocks(exercises, where: 'Day "$title"'),
    );
  }

  CommonSection _parseCommonSection(Object? raw, {required int index}) {
    final where = 'Common section ${index + 1}';
    final json = _asObject(raw, where);
    final title = _requiredString(json['name'], '$where needs a name.');
    final exercises = _asList(
      json['exercises'],
      '$where ("$title") needs an exercises list.',
    );
    return CommonSection.create(
      sectionId: newId(),
      title: title,
      blocks: _parseBlocks(exercises, where: 'Section "$title"'),
    );
  }

  List<ExerciseBlock> _parseBlocks(List<dynamic> exercises, {required String where}) {
    final blocks = <ExerciseBlock>[];
    for (var i = 0; i < exercises.length; i++) {
      final location = '$where, exercise ${i + 1}';
      final json = _asObject(exercises[i], location);
      final type = _requiredString(json['type'], '$location is missing a type.');
      if (type == 'single') {
        blocks.add(_parseSingle(json['exercise'], location));
      } else if (type == 'super-set') {
        blocks.add(_parseSuperset(json['exercise'], location));
      } else {
        throw PlanImportException(
          '$location has type "$type". Use "single" or "super-set".',
        );
      }
    }
    return blocks;
  }

  ExerciseBlock _parseSingle(Object? raw, String location) {
    final exercise = _parsePrescription(
      _asObject(raw, '$location (single) needs an exercise object.'),
      location,
    );
    return ExerciseBlock.create(
      blockId: newId(),
      kind: BlockKind.single,
      exercises: [exercise],
    );
  }

  ExerciseBlock _parseSuperset(Object? raw, String location) {
    final items = _asList(
      raw,
      '$location (super-set) needs a list of exercises.',
    );
    if (items.length < 2) {
      throw PlanImportException(
        '$location is a super-set and needs at least two exercises.',
      );
    }
    final exercises = <ExercisePrescription>[];
    for (var i = 0; i < items.length; i++) {
      exercises.add(
        _parsePrescription(
          _asObject(items[i], '$location, movement ${i + 1}'),
          '$location, movement ${i + 1}',
        ),
      );
    }
    return ExerciseBlock.create(
      blockId: newId(),
      kind: BlockKind.superset,
      exercises: exercises,
    );
  }

  ExercisePrescription _parsePrescription(
    Map<String, dynamic> json,
    String location,
  ) {
    final title = _requiredString(
      json['title'],
      '$location needs an exercise title.',
    );
    final sets = _asInt(json['sets'], '$location ("$title") sets');
    if (sets == null || sets < 1) {
      throw PlanImportException(
        '$location ("$title") needs at least 1 set.',
      );
    }

    final reps = _asInt(json['times'], '$location ("$title") times');
    final duration =
        _asInt(json['duration'], '$location ("$title") duration');
    if (reps != null && duration != null) {
      throw PlanImportException(
        '$location ("$title") must have either times or duration, not both.',
      );
    }
    if (reps == null && duration == null) {
      throw PlanImportException(
        '$location ("$title") needs times (reps) or duration (seconds).',
      );
    }
    if (reps != null && reps < 1) {
      throw PlanImportException(
        '$location ("$title") times must be at least 1.',
      );
    }
    if (duration != null && duration < 1) {
      throw PlanImportException(
        '$location ("$title") duration must be at least 1 second.',
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
    final mediaUri = _optionalNonEmpty(json['mediaUri']) ??
        _optionalNonEmpty(json['svgPath']) ??
        match?.assetPath;
    final mediaSourceName = _optionalString(json['mediaSource']);
    final mediaKindName = _optionalString(json['mediaKind']);

    return ExercisePrescription.create(
      prescriptionId: newId(),
      title: title,
      prescribedSets: sets,
      prescribedReps: reps,
      prescribedDurationSeconds: duration,
      targetAreaIds: targetAreaIds,
      catalogExerciseId: catalogId,
      svgPath: mediaUri,
      mediaUri: mediaUri,
      mediaSource: mediaUri == null
          ? ExerciseMediaSource.none
          : _mediaSource(mediaSourceName),
      mediaKind: mediaUri == null
          ? ExerciseMediaKind.unknown
          : _mediaKind(mediaKindName, mediaUri),
    );
  }
}

String defaultNewId() => newId();

Map<String, dynamic> _asObject(Object? value, String what) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw PlanImportException('$what is not a JSON object.');
}

List<dynamic> _asList(Object? value, String what) {
  if (value is List) return value;
  throw PlanImportException('$what is not a JSON array.');
}

String _requiredString(Object? value, String message) {
  if (value is! String || value.trim().isEmpty) {
    throw PlanImportException(message);
  }
  return value.trim();
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
    if (value.name == raw) return value;
  }
  final lower = path.toLowerCase();
  if (lower.endsWith('.svg')) return ExerciseMediaKind.svg;
  if (lower.endsWith('.gif')) return ExerciseMediaKind.gif;
  return ExerciseMediaKind.image;
}

List<String> _stringList(Object? value) {
  if (value == null) return const [];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}

int? _asInt(Object? value, String what) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw PlanImportException('$what must be a whole number.');
}
