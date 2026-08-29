import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/models.dart';
import '../../data/session_repository.dart';

/// Thrown when a live-workout action is not valid in the current phase.
class WorkoutActionException implements Exception {
  const WorkoutActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Live session state: active log, set logging, rest clock, duration timer, rating.
///
/// Created with a session id. Rest is UI-only and is never written to Isar.
class WorkoutController extends GetxController {
  WorkoutController({
    required this.sessionId,
    required SessionRepository sessions,
    DateTime Function()? clock,
  })  : _sessions = sessions,
        _now = clock ?? DateTime.now;

  final int sessionId;
  final SessionRepository _sessions;
  final DateTime Function() _now;

  WorkoutSession? _session;
  int? _activeLogIndex;

  int restElapsedSeconds = 0;
  Stopwatch? _restWatch;
  Timer? _restTimer;

  /// Remaining seconds for duration work. Negative means overtime.
  int? durationRemainingSeconds;
  bool durationTimerStarted = false;
  Timer? _durationTimer;

  WorkoutSession? get session => _session;

  ExerciseLog? get activeLog {
    final session = _session;
    final index = _activeLogIndex;
    if (session == null || index == null) return null;
    if (index < 0 || index >= session.exerciseLogs.length) return null;
    return session.exerciseLogs[index];
  }

  int? get activeLogIndex => _activeLogIndex;

  bool get isLive => _session?.status == SessionStatus.inProgress;

  bool get isResting => _restTimer != null;

  bool get isDurationRunning => _durationTimer != null;

  /// First block that still has an unrated log. Null when everything is rated.
  String? get currentBlockId {
    final session = _session;
    if (session == null) return null;
    for (final log in session.exerciseLogs) {
      if (log.difficulty == null) return log.blockId;
    }
    return null;
  }

  List<ExerciseLog> get currentBlockLogs {
    final blockId = currentBlockId;
    final session = _session;
    if (blockId == null || session == null) return const [];
    return [
      for (final log in session.exerciseLogs)
        if (log.blockId == blockId) log,
    ];
  }

  /// True while any log in the current block still needs prescribed sets.
  bool get isPrescribedPhase {
    for (final log in currentBlockLogs) {
      if (log.sets.length < log.prescribedSets) return true;
    }
    return false;
  }

  bool get inExtrasPhase =>
      currentBlockId != null && !isPrescribedPhase && isLive;

  bool get allLogsRated {
    final session = _session;
    if (session == null || session.exerciseLogs.isEmpty) return false;
    return session.exerciseLogs.every((log) => log.difficulty != null);
  }

  /// 1-based set index shown in the live header for the active exercise.
  int get headerSetIndex => (activeLog?.sets.length ?? 0) + 1;

  int get headerPrescribedSets => activeLog?.prescribedSets ?? 0;

  Future<void> load() async {
    _session = await _sessions.byId(sessionId);
    if (_session == null) {
      throw const WorkoutActionException('That workout is no longer here.');
    }
    _selectInitialActive();
    _syncDurationForActive();
    update();
  }

  bool canLogSet(ExerciseLog log) =>
      log.prescribedDurationSeconds == null && _canAcceptLog(log);

  bool canLogTime(ExerciseLog log) =>
      log.prescribedDurationSeconds != null && _canAcceptLog(log);

  bool canRate(ExerciseLog log) {
    if (!isLive || isPrescribedPhase) return false;
    if (log.difficulty != null) return false;
    return _inCurrentBlock(log);
  }

  Future<void> logSet({
    int? reps,
    double? weightKg,
    ExerciseLog? log,
  }) async {
    _ensureLive();
    final target = log ?? activeLog;
    if (target == null || !canLogSet(target)) {
      throw const WorkoutActionException('This exercise cannot take a set yet.');
    }
    if (reps == null || reps < 1) {
      throw const WorkoutActionException('Reps are required.');
    }
    _focus(target);
    _appendSet(
      target,
      SetLog.create(
        setIndex: target.sets.length + 1,
        completedAt: _now().toUtc(),
        reps: reps,
        weightKg: weightKg,
      ),
    );
    _resetRestKeepingStopped();
    _advanceActiveAfterLog();
    await _persist();
  }

  Future<void> logTime({ExerciseLog? log}) async {
    _ensureLive();
    final target = log ?? activeLog;
    if (target == null || !canLogTime(target)) {
      throw const WorkoutActionException('This exercise cannot take a time yet.');
    }
    final prescribed = target.prescribedDurationSeconds!;
    final loggingActive = _indexOf(target) == _activeLogIndex;
    final remaining = loggingActive
        ? (durationRemainingSeconds ?? prescribed)
        : prescribed;
    final seconds = loggingActive && durationTimerStarted
        ? prescribed - remaining
        : prescribed;
    _stopDurationTimer();
    _focus(target);
    _appendSet(
      target,
      SetLog.create(
        setIndex: target.sets.length + 1,
        completedAt: _now().toUtc(),
        durationSeconds: seconds,
      ),
    );
    _resetRestKeepingStopped();
    _advanceActiveAfterLog();
    await _persist();
  }

  Future<void> rate(int difficulty, {ExerciseLog? log}) async {
    _ensureLive();
    if (difficulty < 1 || difficulty > 5) {
      throw const WorkoutActionException('Rate this exercise from 1 to 5.');
    }
    final target = log ?? activeLog;
    if (target == null || !canRate(target)) {
      throw const WorkoutActionException(
        'Rate after this block’s prescribed sets are logged.',
      );
    }
    _focus(target);
    target.difficulty = difficulty;
    target.completedAt = _now().toUtc();
    _selectInitialActive();
    _syncDurationForActive();
    await _persist();
    if (allLogsRated && isLive) {
      await finish();
    }
  }

  Future<void> finish() async {
    _ensureLive();
    _stopTimers();
    _session!.status = SessionStatus.completed;
    _session!.endedAt = _now().toUtc();
    await _persist();
  }

  Future<void> discard() async {
    _ensureLive();
    _stopTimers();
    _session!.status = SessionStatus.abandoned;
    _session!.endedAt = _now().toUtc();
    await _persist();
  }

  void startRest() {
    if (_restTimer != null) return;
    _restWatch = Stopwatch()..start();
    restElapsedSeconds = 0;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      restElapsedSeconds = _restWatch?.elapsed.inSeconds ?? restElapsedSeconds;
      update();
    });
    update();
  }

  void resetRest() {
    _resetRestKeepingStopped();
    update();
  }

  void startDurationCountdown() {
    final log = activeLog;
    final prescribed = log?.prescribedDurationSeconds;
    if (prescribed == null) return;
    if (_durationTimer != null) return;
    durationRemainingSeconds ??= prescribed;
    durationTimerStarted = true;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      durationRemainingSeconds = (durationRemainingSeconds ?? 0) - 1;
      update();
    });
    update();
  }

  /// Test hook so duration logging can be checked without waiting on a timer.
  @visibleForTesting
  void debugAdvanceDuration([int seconds = 1]) {
    durationRemainingSeconds ??= activeLog?.prescribedDurationSeconds ?? 0;
    durationTimerStarted = true;
    durationRemainingSeconds = (durationRemainingSeconds ?? 0) - seconds;
    update();
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }

  bool _canAcceptLog(ExerciseLog log) {
    if (!isLive || log.difficulty != null) return false;
    if (!_inCurrentBlock(log)) return false;
    if (isPrescribedPhase) {
      return _indexOf(log) == _activeLogIndex;
    }
    return true;
  }

  bool _inCurrentBlock(ExerciseLog log) {
    final blockId = currentBlockId;
    return blockId != null && log.blockId == blockId;
  }

  void _focus(ExerciseLog log) {
    final index = _indexOf(log);
    if (index == null) return;
    if (_activeLogIndex != index) {
      _activeLogIndex = index;
      _syncDurationForActive();
    }
  }

  void _appendSet(ExerciseLog log, SetLog set) {
    log.sets = [...log.sets, set];
    _session!.exerciseLogs = List<ExerciseLog>.from(_session!.exerciseLogs);
  }

  void _advanceActiveAfterLog() {
    final blockId = currentBlockId;
    if (blockId == null) {
      _activeLogIndex = null;
      _syncDurationForActive();
      return;
    }
    final after = _activeLogIndex;
    if (isPrescribedPhase && after != null) {
      final next = _nextNeedingPrescribedSets(afterIndex: after, blockId: blockId);
      _activeLogIndex = next ?? _firstUnratedIndex(blockId);
    } else if (activeLog?.difficulty != null) {
      _activeLogIndex = _firstUnratedIndex(blockId);
    }
    _syncDurationForActive();
  }

  void _selectInitialActive() {
    final blockId = currentBlockId;
    if (blockId == null) {
      _activeLogIndex = null;
      return;
    }
    final needing = _firstNeedingPrescribedSets(blockId);
    _activeLogIndex = needing ?? _firstUnratedIndex(blockId);
  }

  List<int> _indicesFor(String blockId) {
    final session = _session!;
    return [
      for (var i = 0; i < session.exerciseLogs.length; i++)
        if (session.exerciseLogs[i].blockId == blockId) i,
    ];
  }

  int? _firstNeedingPrescribedSets(String blockId) {
    final indices = _indicesFor(blockId);
    var bestIndex = -1;
    var bestCount = 1 << 30;
    for (final i in indices) {
      final log = _session!.exerciseLogs[i];
      if (log.sets.length >= log.prescribedSets) continue;
      if (log.sets.length < bestCount) {
        bestCount = log.sets.length;
        bestIndex = i;
      }
    }
    return bestIndex < 0 ? null : bestIndex;
  }

  int? _firstUnratedIndex(String blockId) {
    for (final i in _indicesFor(blockId)) {
      if (_session!.exerciseLogs[i].difficulty == null) return i;
    }
    return null;
  }

  int? _nextNeedingPrescribedSets({
    required int afterIndex,
    required String blockId,
  }) {
    final indices = _indicesFor(blockId);
    final pos = indices.indexOf(afterIndex);
    if (pos < 0) return _firstNeedingPrescribedSets(blockId);
    final rotated = [
      ...indices.sublist(pos + 1),
      ...indices.sublist(0, pos + 1),
    ];
    for (final i in rotated) {
      final log = _session!.exerciseLogs[i];
      if (log.sets.length < log.prescribedSets) return i;
    }
    return null;
  }

  int? _indexOf(ExerciseLog log) {
    final session = _session;
    if (session == null) return null;
    for (var i = 0; i < session.exerciseLogs.length; i++) {
      if (identical(session.exerciseLogs[i], log)) return i;
      if (session.exerciseLogs[i].prescriptionId == log.prescriptionId) {
        return i;
      }
    }
    return null;
  }

  void _syncDurationForActive() {
    _stopDurationTimer();
    durationTimerStarted = false;
    final prescribed = activeLog?.prescribedDurationSeconds;
    durationRemainingSeconds = prescribed;
  }

  void _resetRestKeepingStopped() {
    _restTimer?.cancel();
    _restTimer = null;
    _restWatch?.stop();
    _restWatch = null;
    restElapsedSeconds = 0;
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _stopTimers() {
    _resetRestKeepingStopped();
    _stopDurationTimer();
  }

  void _ensureLive() {
    if (!isLive) {
      throw const WorkoutActionException('This workout has already ended.');
    }
  }

  Future<void> _persist() async {
    await _sessions.save(_session!);
    update();
  }
}
