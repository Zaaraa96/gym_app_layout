import 'package:isar/isar.dart';

import '../../domain/models/models.dart' as domain;
import 'workout_plan.dart';
import 'workout_session.dart';

/// Maps product [domain.WorkoutPlan] graphs onto Isar collection rows.
WorkoutPlan planToIsar(domain.WorkoutPlan plan) {
  final row = WorkoutPlan()
    ..id = plan.id == domain.unassignedLocalId ? Isar.autoIncrement : plan.id
    ..uuid = plan.uuid
    ..dirty = plan.dirty
    ..title = plan.title
    ..source = plan.source
    ..createdAt = plan.createdAt
    ..updatedAt = plan.updatedAt
    ..days = [for (final day in plan.days) _dayToIsar(day)]
    ..commonSections = [
      for (final section in plan.commonSections) _sectionToIsar(section),
    ];
  return row;
}

domain.WorkoutPlan planFromIsar(WorkoutPlan row) {
  return domain.WorkoutPlan.create(
    uuid: row.uuid,
    dirty: row.dirty,
    title: row.title,
    source: row.source,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    days: [for (final day in row.days) _dayFromIsar(day)],
    commonSections: [
      for (final section in row.commonSections) _sectionFromIsar(section),
    ],
  )..id = row.id;
}

PlanDay _dayToIsar(domain.PlanDay day) {
  return PlanDay()
    ..dayId = day.dayId
    ..title = day.title
    ..summary = day.summary
    ..blocks = [for (final block in day.blocks) _blockToIsar(block)];
}

domain.PlanDay _dayFromIsar(PlanDay day) {
  return domain.PlanDay.create(
    dayId: day.dayId,
    title: day.title,
    summary: day.summary,
    blocks: [for (final block in day.blocks) _blockFromIsar(block)],
  );
}

CommonSection _sectionToIsar(domain.CommonSection section) {
  return CommonSection()
    ..sectionId = section.sectionId
    ..title = section.title
    ..blocks = [for (final block in section.blocks) _blockToIsar(block)];
}

domain.CommonSection _sectionFromIsar(CommonSection section) {
  return domain.CommonSection.create(
    sectionId: section.sectionId,
    title: section.title,
    blocks: [for (final block in section.blocks) _blockFromIsar(block)],
  );
}

ExerciseBlock _blockToIsar(domain.ExerciseBlock block) {
  return ExerciseBlock()
    ..blockId = block.blockId
    ..kind = block.kind
    ..svgPath = block.svgPath
    ..mediaUri = block.mediaUri
    ..mediaSource = block.mediaSource
    ..mediaKind = block.mediaKind
    ..exercises = [
      for (final exercise in block.exercises) _prescriptionToIsar(exercise),
    ];
}

domain.ExerciseBlock _blockFromIsar(ExerciseBlock block) {
  return domain.ExerciseBlock.create(
    blockId: block.blockId,
    kind: block.kind,
    svgPath: block.svgPath,
    mediaUri: block.mediaUri,
    mediaSource: block.mediaSource,
    mediaKind: block.mediaKind,
    exercises: [
      for (final exercise in block.exercises) _prescriptionFromIsar(exercise),
    ],
  );
}

ExercisePrescription _prescriptionToIsar(domain.ExercisePrescription exercise) {
  return ExercisePrescription()
    ..prescriptionId = exercise.prescriptionId
    ..title = exercise.title
    ..prescribedSets = exercise.prescribedSets
    ..prescribedReps = exercise.prescribedReps
    ..prescribedDurationSeconds = exercise.prescribedDurationSeconds
    ..targetWeightKg = exercise.targetWeightKg;
}

domain.ExercisePrescription _prescriptionFromIsar(ExercisePrescription exercise) {
  return domain.ExercisePrescription.create(
    prescriptionId: exercise.prescriptionId,
    title: exercise.title,
    prescribedSets: exercise.prescribedSets,
    prescribedReps: exercise.prescribedReps,
    prescribedDurationSeconds: exercise.prescribedDurationSeconds,
    targetWeightKg: exercise.targetWeightKg,
  );
}

/// Maps product [domain.WorkoutSession] graphs onto Isar collection rows.
WorkoutSession sessionToIsar(domain.WorkoutSession session) {
  final row = WorkoutSession()
    ..id = session.id == domain.unassignedLocalId
        ? Isar.autoIncrement
        : session.id
    ..uuid = session.uuid
    ..planId = session.planId
    ..planDayId = session.planDayId
    ..planTitleSnapshot = session.planTitleSnapshot
    ..dayTitleSnapshot = session.dayTitleSnapshot
    ..includedCommonSectionIds = List<String>.from(session.includedCommonSectionIds)
    ..startedAt = session.startedAt
    ..endedAt = session.endedAt
    ..updatedAt = session.updatedAt
    ..dirty = session.dirty
    ..status = session.status
    ..exerciseLogs = [for (final log in session.exerciseLogs) _logToIsar(log)];
  return row;
}

domain.WorkoutSession sessionFromIsar(WorkoutSession row) {
  return domain.WorkoutSession.create(
    uuid: row.uuid,
    dirty: row.dirty,
    planId: row.planId,
    planDayId: row.planDayId,
    planTitleSnapshot: row.planTitleSnapshot,
    dayTitleSnapshot: row.dayTitleSnapshot,
    startedAt: row.startedAt,
    updatedAt: row.updatedAt,
    endedAt: row.endedAt,
    status: row.status,
    includedCommonSectionIds: List<String>.from(row.includedCommonSectionIds),
    exerciseLogs: [for (final log in row.exerciseLogs) _logFromIsar(log)],
  )..id = row.id;
}

ExerciseLog _logToIsar(domain.ExerciseLog log) {
  return ExerciseLog()
    ..prescriptionId = log.prescriptionId
    ..blockId = log.blockId
    ..blockKind = log.blockKind
    ..fromCommonSection = log.fromCommonSection
    ..exerciseTitle = log.exerciseTitle
    ..exerciseTitleKey = log.exerciseTitleKey
    ..prescribedSets = log.prescribedSets
    ..prescribedReps = log.prescribedReps
    ..prescribedDurationSeconds = log.prescribedDurationSeconds
    ..sets = [for (final set in log.sets) _setToIsar(set)]
    ..difficulty = log.difficulty
    ..completedAt = log.completedAt;
}

domain.ExerciseLog _logFromIsar(ExerciseLog log) {
  return domain.ExerciseLog.create(
    prescriptionId: log.prescriptionId,
    blockId: log.blockId,
    blockKind: log.blockKind,
    fromCommonSection: log.fromCommonSection,
    exerciseTitle: log.exerciseTitle,
    exerciseTitleKey: log.exerciseTitleKey,
    prescribedSets: log.prescribedSets,
    prescribedReps: log.prescribedReps,
    prescribedDurationSeconds: log.prescribedDurationSeconds,
    difficulty: log.difficulty,
    completedAt: log.completedAt,
    sets: [for (final set in log.sets) _setFromIsar(set)],
  );
}

SetLog _setToIsar(domain.SetLog set) {
  return SetLog()
    ..setIndex = set.setIndex
    ..reps = set.reps
    ..weightKg = set.weightKg
    ..durationSeconds = set.durationSeconds
    ..completedAt = set.completedAt;
}

domain.SetLog _setFromIsar(SetLog set) {
  return domain.SetLog.create(
    setIndex: set.setIndex,
    completedAt: set.completedAt,
    reps: set.reps,
    weightKg: set.weightKg,
    durationSeconds: set.durationSeconds,
  );
}
