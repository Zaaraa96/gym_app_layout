import '../../domain/models/models.dart';

DateTime? _date(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.parse(raw).toUtc();
}

String _iso(DateTime value) => value.toUtc().toIso8601String();

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
  }
  return fallback;
}

/// HTTP DTO for a [WorkoutPlan]. Identity is [WorkoutPlan.uuid], never Isar [Id].
class PlanDto {
  PlanDto.fromEntity(WorkoutPlan plan)
      : id = plan.uuid,
        title = plan.title,
        source = plan.source.name,
        createdAt = _iso(plan.createdAt),
        updatedAt = _iso(plan.updatedAt),
        days = [for (final day in plan.days) _dayToJson(day)],
        commonSections = [
          for (final section in plan.commonSections) _sectionToJson(section),
        ];

  PlanDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        title = json['title'] as String,
        source = json['source'] as String,
        createdAt = json['createdAt'] as String,
        updatedAt = json['updatedAt'] as String,
        days = _asMaps(json['days']),
        commonSections = _asMaps(json['commonSections']);

  final String id;
  final String title;
  final String source;
  final String createdAt;
  final String updatedAt;
  final List<Map<String, dynamic>> days;
  final List<Map<String, dynamic>> commonSections;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source': source,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'days': days,
        'commonSections': commonSections,
      };

  WorkoutPlan toEntity() {
    return WorkoutPlan.create(
      uuid: id,
      dirty: false,
      title: title,
      source: _enum(PlanSource.values, source, PlanSource.created),
      createdAt: _date(createdAt)!,
      updatedAt: _date(updatedAt)!,
      days: [for (final day in days) _dayFromJson(day)],
      commonSections: [
        for (final section in commonSections) _sectionFromJson(section),
      ],
    );
  }
}

/// HTTP DTO for a [WorkoutSession]. Identity is [WorkoutSession.uuid].
class SessionDto {
  SessionDto.fromEntity(WorkoutSession session)
      : id = session.uuid,
        planId = session.planId,
        planDayId = session.planDayId,
        planTitleSnapshot = session.planTitleSnapshot,
        dayTitleSnapshot = session.dayTitleSnapshot,
        includedCommonSectionIds = session.includedCommonSectionIds,
        startedAt = _iso(session.startedAt),
        endedAt = session.endedAt == null ? null : _iso(session.endedAt!),
        updatedAt = _iso(session.updatedAt),
        status = session.status.name,
        exerciseLogs = [
          for (final log in session.exerciseLogs) _logToJson(log),
        ];

  SessionDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        planId = json['planId'] as String,
        planDayId = json['planDayId'] as String,
        planTitleSnapshot = json['planTitleSnapshot'] as String,
        dayTitleSnapshot = json['dayTitleSnapshot'] as String,
        includedCommonSectionIds = [
          for (final id
              in json['includedCommonSectionIds'] as List? ?? const [])
            id as String,
        ],
        startedAt = json['startedAt'] as String,
        endedAt = json['endedAt'] as String?,
        updatedAt = json['updatedAt'] as String? ?? json['startedAt'] as String,
        status = json['status'] as String,
        exerciseLogs = _asMaps(json['exerciseLogs']);

  final String id;
  final String planId;
  final String planDayId;
  final String planTitleSnapshot;
  final String dayTitleSnapshot;
  final List<String> includedCommonSectionIds;
  final String startedAt;
  final String? endedAt;
  final String updatedAt;
  final String status;
  final List<Map<String, dynamic>> exerciseLogs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'planDayId': planDayId,
        'planTitleSnapshot': planTitleSnapshot,
        'dayTitleSnapshot': dayTitleSnapshot,
        'includedCommonSectionIds': includedCommonSectionIds,
        'startedAt': startedAt,
        'endedAt': endedAt,
        'updatedAt': updatedAt,
        'status': status,
        'exerciseLogs': exerciseLogs,
      };

  WorkoutSession toEntity() {
    return WorkoutSession.create(
      uuid: id,
      dirty: false,
      planId: planId,
      planDayId: planDayId,
      planTitleSnapshot: planTitleSnapshot,
      dayTitleSnapshot: dayTitleSnapshot,
      startedAt: _date(startedAt)!,
      updatedAt: _date(updatedAt)!,
      endedAt: _date(endedAt),
      status: _enum(SessionStatus.values, status, SessionStatus.completed),
      includedCommonSectionIds: includedCommonSectionIds,
      exerciseLogs: [for (final log in exerciseLogs) _logFromJson(log)],
    );
  }
}

List<Map<String, dynamic>> _asMaps(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map<String, dynamic>)
        item
      else if (item is Map)
        Map<String, dynamic>.from(item),
  ];
}

Map<String, dynamic> _dayToJson(PlanDay day) => {
      'dayId': day.dayId,
      'title': day.title,
      'summary': day.summary,
      'blocks': [for (final block in day.blocks) _blockToJson(block)],
    };

PlanDay _dayFromJson(Map<String, dynamic> json) => PlanDay.create(
      dayId: json['dayId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      blocks: [
        for (final block in _asMaps(json['blocks'])) _blockFromJson(block)
      ],
    );

Map<String, dynamic> _sectionToJson(CommonSection section) => {
      'sectionId': section.sectionId,
      'title': section.title,
      'blocks': [for (final block in section.blocks) _blockToJson(block)],
    };

CommonSection _sectionFromJson(Map<String, dynamic> json) =>
    CommonSection.create(
      sectionId: json['sectionId'] as String,
      title: json['title'] as String,
      blocks: [
        for (final block in _asMaps(json['blocks'])) _blockFromJson(block)
      ],
    );

Map<String, dynamic> _blockToJson(ExerciseBlock block) => {
      'blockId': block.blockId,
      'kind': block.kind.name,
      'svgPath': block.svgPath,
      'mediaUri': block.mediaUri,
      'mediaSource': block.mediaSource.name,
      'mediaKind': block.mediaKind.name,
      'exercises': [
        for (final exercise in block.exercises) _prescriptionToJson(exercise),
      ],
    };

ExerciseBlock _blockFromJson(Map<String, dynamic> json) => ExerciseBlock.create(
      blockId: json['blockId'] as String,
      kind: _enum(BlockKind.values, json['kind'], BlockKind.single),
      svgPath: json['svgPath'] as String?,
      mediaUri: json['mediaUri'] as String?,
      mediaSource: _enum(
        ExerciseMediaSource.values,
        json['mediaSource'],
        ExerciseMediaSource.none,
      ),
      mediaKind: _enum(
        ExerciseMediaKind.values,
        json['mediaKind'],
        ExerciseMediaKind.unknown,
      ),
      exercises: [
        for (final exercise in _asMaps(json['exercises']))
          _prescriptionFromJson(exercise),
      ],
    );

Map<String, dynamic> _prescriptionToJson(ExercisePrescription exercise) => {
      'prescriptionId': exercise.prescriptionId,
      'title': exercise.title,
      'prescribedSets': exercise.prescribedSets,
      'prescribedReps': exercise.prescribedReps,
      'prescribedDurationSeconds': exercise.prescribedDurationSeconds,
      'targetWeightKg': exercise.targetWeightKg,
    };

ExercisePrescription _prescriptionFromJson(Map<String, dynamic> json) =>
    ExercisePrescription.create(
      prescriptionId: json['prescriptionId'] as String,
      title: json['title'] as String,
      prescribedSets: json['prescribedSets'] as int,
      prescribedReps: json['prescribedReps'] as int?,
      prescribedDurationSeconds: json['prescribedDurationSeconds'] as int?,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
    );

Map<String, dynamic> _logToJson(ExerciseLog log) => {
      'prescriptionId': log.prescriptionId,
      'blockId': log.blockId,
      'blockKind': log.blockKind.name,
      'fromCommonSection': log.fromCommonSection,
      'exerciseTitle': log.exerciseTitle,
      'exerciseTitleKey': log.exerciseTitleKey,
      'prescribedSets': log.prescribedSets,
      'prescribedReps': log.prescribedReps,
      'prescribedDurationSeconds': log.prescribedDurationSeconds,
      'difficulty': log.difficulty,
      'completedAt': log.completedAt == null ? null : _iso(log.completedAt!),
      'sets': [for (final set in log.sets) _setToJson(set)],
    };

ExerciseLog _logFromJson(Map<String, dynamic> json) => ExerciseLog.create(
      prescriptionId: json['prescriptionId'] as String,
      blockId: json['blockId'] as String,
      blockKind: _enum(BlockKind.values, json['blockKind'], BlockKind.single),
      fromCommonSection: json['fromCommonSection'] as bool? ?? false,
      exerciseTitle: json['exerciseTitle'] as String,
      exerciseTitleKey: json['exerciseTitleKey'] as String,
      prescribedSets: json['prescribedSets'] as int,
      prescribedReps: json['prescribedReps'] as int?,
      prescribedDurationSeconds: json['prescribedDurationSeconds'] as int?,
      difficulty: json['difficulty'] as int?,
      completedAt: _date(json['completedAt']),
      sets: [for (final set in _asMaps(json['sets'])) _setFromJson(set)],
    );

Map<String, dynamic> _setToJson(SetLog set) => {
      'setIndex': set.setIndex,
      'reps': set.reps,
      'weightKg': set.weightKg,
      'durationSeconds': set.durationSeconds,
      'completedAt': _iso(set.completedAt),
    };

SetLog _setFromJson(Map<String, dynamic> json) => SetLog.create(
      setIndex: json['setIndex'] as int,
      completedAt: _date(json['completedAt'])!,
      reps: json['reps'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
    );
