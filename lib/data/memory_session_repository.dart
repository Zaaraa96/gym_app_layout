import 'dart:async';

import '../domain/models/models.dart';
import '../domain/new_id.dart';
import '../domain/session_repository.dart';

/// In-memory [SessionRepository] for Flutter web. Isar 3.1 cannot open on web.
class MemorySessionRepository implements SessionRepository {
  final _byId = <int, WorkoutSession>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Future<WorkoutSession?> byId(int id) async => _byId[id];

  @override
  Future<WorkoutSession?> byUuid(String uuid) async {
    for (final session in _byId.values) {
      if (session.uuid == uuid) return session;
    }
    return null;
  }

  @override
  Future<int> save(WorkoutSession session) {
    session.updatedAt = DateTime.now().toUtc();
    session.dirty = true;
    return _put(session);
  }

  @override
  Future<int> putSynced(WorkoutSession session) {
    session.dirty = false;
    return _put(session);
  }

  @override
  Future<List<WorkoutSession>> unsynced() async =>
      _byId.values.where((session) => session.dirty).toList();

  @override
  Future<bool> delete(int id) async {
    final removed = _byId.remove(id) != null;
    if (removed) _changes.add(null);
    return removed;
  }

  @override
  Future<WorkoutSession?> inProgress() async {
    for (final session in _byId.values) {
      if (session.status == SessionStatus.inProgress) return session;
    }
    return null;
  }

  @override
  Future<WorkoutSession?> lastCompleted({String? planId}) async {
    final matches = _completed(planId: planId)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) async {
    final matches = _completed(planId: planId)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return matches;
  }

  @override
  Future<List<WorkoutSession>> forMonth(DateTime month) async {
    final start = DateTime.utc(month.year, month.month);
    final end = DateTime.utc(month.year, month.month + 1);
    return _inRange(start, end)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  @override
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _inRange(start, end)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  @override
  Stream<void> watch({bool fireImmediately = false}) async* {
    if (fireImmediately) yield null;
    yield* _changes.stream;
  }

  List<WorkoutSession> _completed({String? planId}) {
    return _byId.values.where((session) {
      if (session.status != SessionStatus.completed) return false;
      if (planId == null) return true;
      return session.planId == planId;
    }).toList();
  }

  List<WorkoutSession> _inRange(DateTime start, DateTime end) {
    return _byId.values.where((session) {
      if (session.status == SessionStatus.abandoned) return false;
      if (session.status != SessionStatus.inProgress &&
          session.status != SessionStatus.completed) {
        return false;
      }
      return !session.startedAt.isBefore(start) &&
          session.startedAt.isBefore(end);
    }).toList();
  }

  Future<int> _put(WorkoutSession session) async {
    if (session.uuid.isEmpty) session.uuid = newUuid();
    if (session.id == unassignedLocalId) {
      session.id = ++_nextId;
    }
    _byId[session.id] = session;
    _changes.add(null);
    return session.id;
  }
}
