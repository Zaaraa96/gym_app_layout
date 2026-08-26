import 'dart:convert';

import 'models/models.dart';
import 'new_id.dart';

/// Thrown when a JSON file cannot be turned into a [WorkoutPlan].
///
/// [message] is safe to show in the UI.
class PlanImportException implements Exception {
  const PlanImportException(this.message);

  final String message;

  @override
  String toString() => message;
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
  WorkoutPlan import(String source) {
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

    final now = (clock ?? DateTime.now)().toUtc();
    return WorkoutPlan.create(
      title: title,
      source: PlanSource.imported,
      createdAt: now,
      updatedAt: now,
      days: days,
      commonSections: commonSections,
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

    return ExercisePrescription.create(
      prescriptionId: newId(),
      title: title,
      prescribedSets: sets,
      prescribedReps: reps,
      prescribedDurationSeconds: duration,
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

int? _asInt(Object? value, String what) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw PlanImportException('$what must be a whole number.');
}
