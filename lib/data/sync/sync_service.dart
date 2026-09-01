import '../../domain/models/models.dart';
import '../../domain/plan_repository.dart';
import '../remote/remote_plan_data_source.dart';
import '../remote/remote_session_data_source.dart';
import '../../domain/session_repository.dart';

/// Pull/push between Isar and HTTP. [watch] stays on the local repositories.
class SyncService {
  SyncService({
    required PlanRepository plans,
    required SessionRepository sessions,
    required RemotePlanDataSource remotePlans,
    required RemoteSessionDataSource remoteSessions,
    this.enabled = true,
    Future<bool> Function()? isOnline,
  })  : _plans = plans,
        _sessions = sessions,
        _remotePlans = remotePlans,
        _remoteSessions = remoteSessions,
        _isOnline = isOnline ?? (() async => true);

  final PlanRepository _plans;
  final SessionRepository _sessions;
  final RemotePlanDataSource _remotePlans;
  final RemoteSessionDataSource _remoteSessions;
  final bool enabled;
  final Future<bool> Function() _isOnline;

  var _running = false;

  /// Pull remote copies, then flush dirty local rows. No-op when offline.
  Future<void> sync() async {
    if (!enabled || _running) return;
    if (!await _isOnline()) return;
    _running = true;
    try {
      await pull();
      await push();
    } finally {
      _running = false;
    }
  }

  /// Last-write-wins on [WorkoutPlan.updatedAt] / [WorkoutSession.updatedAt].
  Future<void> pull() async {
    if (!enabled) return;
    await _pullPlans();
    await _pullSessions();
  }

  Future<void> push() async {
    if (!enabled) return;
    if (!await _isOnline()) return;
    for (final plan in await _plans.unsynced()) {
      await _remotePlans.upsert(plan);
      await _plans.putSynced(plan);
    }
    for (final session in await _sessions.unsynced()) {
      await _remoteSessions.upsert(session);
      await _sessions.putSynced(session);
    }
  }

  Future<void> _pullPlans() async {
    final remote = await _remotePlans.fetchAll();
    for (final incoming in remote) {
      final local = await _plans.byUuid(incoming.uuid);
      if (local != null && local.updatedAt.isAfter(incoming.updatedAt)) {
        continue;
      }
      if (local != null) incoming.id = local.id;
      await _plans.putSynced(incoming);
    }
  }

  Future<void> _pullSessions() async {
    final remote = await _remoteSessions.fetchAll();
    for (final incoming in remote) {
      final local = await _sessions.byUuid(incoming.uuid);
      if (local != null && local.updatedAt.isAfter(incoming.updatedAt)) {
        continue;
      }
      if (local != null) incoming.id = local.id;
      await _sessions.putSynced(incoming);
    }
  }
}
