import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/models/models.dart';
import '../../domain/session_repository.dart';

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

  /// [WorkoutSession.uuid], not a local row key.
  final String sessionId;
  final SessionRepository _sessions;
  final DateTime Function() _now;

  WorkoutSession? _session;
  int? _activeLogIndex;

  /// Countdown seconds left while resting. 0 when not resting.
  int restRemainingSeconds = 0;

  /// Default rest length after Save set / Log time.
  static const int defaultRestSeconds = 60;

  /// Extra rest granted by +15s.
  static const int restBumpSeconds = 15;

  Timer? _restTimer;

  /// Remaining seconds for duration work. Negative means overtime.
  int? durationRemainingSeconds;
  bool durationTimerStarted = false;
  Timer? _durationTimer;

  /// After the last movement is finished, UI shows a short beat before [finish].
  bool sessionDoneBeat = false;

  /// Difficulty of the last rate/skip that triggered [sessionDoneBeat] (null = skip).
  int? sessionDoneDifficulty;

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

  /// First block that still has an unfinished log. Null when everything is done.
  String? get currentBlockId {
    final session = _session;
    if (session == null) return null;
    for (final log in session.exerciseLogs) {
      if (!log.isComplete) return log.blockId;
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

  bool get allLogsComplete {
    final session = _session;
    if (session == null || session.exerciseLogs.isEmpty) return false;
    return session.exerciseLogs.every((log) => log.isComplete);
  }

  /// Kept for older tests; same as [allLogsComplete].
  bool get allLogsRated => allLogsComplete;

  /// 1-based set index shown in the live header for the active exercise.
  int get headerSetIndex => (activeLog?.sets.length ?? 0) + 1;

  int get headerPrescribedSets => activeLog?.prescribedSets ?? 0;

  /// Partner in the same block still unfinished (for “then …” / orientation).
  ExerciseLog? get companionCueLog {
    final active = activeLog;
    if (active == null) return null;
    for (final log in currentBlockLogs) {
      if (log.prescriptionId == active.prescriptionId) continue;
      if (!log.isComplete) return log;
    }
    return null;
  }

  Future<void> load() async {
    _session = await _sessions.byUuid(sessionId);
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
    if (log.isComplete) return false;
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
      throw const WorkoutActionException(
          'This exercise cannot take a set yet.');
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
    _advanceActiveAfterLog();
    _startRestAfterLog();
    await _persist();
  }

  Future<void> logTime({ExerciseLog? log}) async {
    _ensureLive();
    final target = log ?? activeLog;
    if (target == null || !canLogTime(target)) {
      throw const WorkoutActionException(
          'This exercise cannot take a time yet.');
    }
    final prescribed = target.prescribedDurationSeconds!;
    final loggingActive = _indexOf(target) == _activeLogIndex;
    final remaining =
        loggingActive ? (durationRemainingSeconds ?? prescribed) : prescribed;
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
    _advanceActiveAfterLog();
    _startRestAfterLog();
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
    await _afterMovementFinished(difficulty);
  }

  /// Finish the movement without a difficulty number.
  Future<void> skipRating({ExerciseLog? log}) async {
    _ensureLive();
    final target = log ?? activeLog;
    if (target == null || !canRate(target)) {
      throw const WorkoutActionException(
        'Skip after this block’s prescribed sets are logged.',
      );
    }
    _focus(target);
    target.difficulty = null;
    target.completedAt = _now().toUtc();
    await _afterMovementFinished(null);
  }

  Future<void> acknowledgeSessionDone() async {
    if (!sessionDoneBeat || !isLive) return;
    sessionDoneBeat = false;
    sessionDoneDifficulty = null;
    await finish();
  }

  Future<void> finish() async {
    _ensureLive();
    _stopTimers();
    sessionDoneBeat = false;
    _session!.status = SessionStatus.completed;
    _session!.endedAt = _now().toUtc();
    await _persist();
  }

  Future<void> discard() async {
    _ensureLive();
    _stopTimers();
    sessionDoneBeat = false;
    _session!.status = SessionStatus.abandoned;
    _session!.endedAt = _now().toUtc();
    await _persist();
  }

  void startRest() {
    if (_restTimer != null) return;
    restRemainingSeconds = defaultRestSeconds;
    // Tick silently — the rest clock widget polls remaining so GetBuilder
    // does not rebuild every second (that was dropping Skip taps).
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restTimer == null) return;
      if (restRemainingSeconds <= 1) {
        endRest();
        return;
      }
      restRemainingSeconds -= 1;
    });
    update();
  }

  /// Add time to the rest countdown (no-op when not resting).
  void addRestSeconds([int seconds = restBumpSeconds]) {
    if (_restTimer == null) return;
    if (seconds <= 0) return;
    restRemainingSeconds += seconds;
  }

  /// Leave rest mode and return to work / rate UI (Skip).
  void endRest() {
    _resetRestKeepingStopped();
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

  Future<void> _afterMovementFinished(int? difficulty) async {
    _selectInitialActive();
    _syncDurationForActive();
    _resetRestKeepingStopped();
    await _persist();
    if (allLogsComplete && isLive) {
      sessionDoneBeat = true;
      sessionDoneDifficulty = difficulty;
      update();
    }
  }

  void _startRestAfterLog() {
    _resetRestKeepingStopped();
    startRest();
  }

  bool _canAcceptLog(ExerciseLog log) {
    if (!isLive || log.isComplete) return false;
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
      final next =
          _nextNeedingPrescribedSets(afterIndex: after, blockId: blockId);
      _activeLogIndex = next ?? _firstUnfinishedIndex(blockId);
    } else if (activeLog?.isComplete == true) {
      _activeLogIndex = _firstUnfinishedIndex(blockId);
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
    _activeLogIndex = needing ?? _firstUnfinishedIndex(blockId);
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

  int? _firstUnfinishedIndex(String blockId) {
    for (final i in _indicesFor(blockId)) {
      if (!_session!.exerciseLogs[i].isComplete) return i;
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
    restRemainingSeconds = 0;
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
