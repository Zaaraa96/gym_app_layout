import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/remote/remote_plan_data_source.dart';
import 'package:gym_app/data/remote/remote_session_data_source.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/data/sync/sync_service.dart';

void main() {
  test('pull keeps the newer local plan and overwrites when remote wins',
      () async {
    final plans = _MemoryPlans();
    final sessions = _MemorySessions();
    final remotePlans = _MemoryRemotePlans();
    final remoteSessions = _MemoryRemoteSessions();

    final local = _plan(
      uuid: 'plan-1',
      title: 'local',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    await plans.putSynced(local);
    local.dirty = true;
    await plans.saveKeepingTime(local);

    remotePlans.store[_plan(
      uuid: 'plan-1',
      title: 'remote-old',
      updatedAt: DateTime.utc(2026, 8, 10),
    ).uuid] = _plan(
      uuid: 'plan-1',
      title: 'remote-old',
      updatedAt: DateTime.utc(2026, 8, 10),
    );

    remotePlans.store['plan-2'] = _plan(
      uuid: 'plan-2',
      title: 'from-server',
      updatedAt: DateTime.utc(2026, 8, 21),
    );

    final sync = SyncService(
      plans: plans,
      sessions: sessions,
      remotePlans: remotePlans,
      remoteSessions: remoteSessions,
    );
    await sync.pull();

    expect((await plans.byUuid('plan-1'))!.title, 'local');
    expect((await plans.byUuid('plan-2'))!.title, 'from-server');
    expect((await plans.byUuid('plan-2'))!.dirty, isFalse);
  });

  test('push flushes dirty rows and clears the dirty flag', () async {
    final plans = _MemoryPlans();
    final sessions = _MemorySessions();
    final remotePlans = _MemoryRemotePlans();
    final remoteSessions = _MemoryRemoteSessions();

    final plan = _plan(
      uuid: 'plan-1',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = plan;

    final session = WorkoutSession.create(
      uuid: 'sess-1',
      planId: 'plan-1',
      planDayId: 'day-1',
      planTitleSnapshot: 'draft',
      dayTitleSnapshot: 'day 1',
      startedAt: DateTime.utc(2026, 8, 20, 10),
      updatedAt: DateTime.utc(2026, 8, 20, 11),
      status: SessionStatus.completed,
      dirty: true,
    )..id = 3;
    sessions.rows[3] = session;

    final sync = SyncService(
      plans: plans,
      sessions: sessions,
      remotePlans: remotePlans,
      remoteSessions: remoteSessions,
    );
    await sync.push();

    expect(remotePlans.store['plan-1']!.title, 'draft');
    expect(remoteSessions.store['sess-1']!.planId, 'plan-1');
    expect((await plans.byUuid('plan-1'))!.dirty, isFalse);
    expect((await sessions.byUuid('sess-1'))!.dirty, isFalse);
  });

  test('sync is a no-op when offline', () async {
    final plans = _MemoryPlans();
    final remotePlans = _MemoryRemotePlans();
    final plan = _plan(
      uuid: 'plan-1',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = plan;

    final sync = SyncService(
      plans: plans,
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
      isOnline: () async => false,
    );
    await sync.sync();
    expect(remotePlans.store, isEmpty);
    expect(plan.dirty, isTrue);
  });

  test('pull overwrites a local session when remote is newer and keeps the Isar id',
      () async {
    final sessions = _MemorySessions();
    final remoteSessions = _MemoryRemoteSessions();

    final local = WorkoutSession.create(
      uuid: 'sess-1',
      planId: 'plan-1',
      planDayId: 'day-1',
      planTitleSnapshot: 'draft',
      dayTitleSnapshot: 'local-day',
      startedAt: DateTime.utc(2026, 8, 20, 10),
      updatedAt: DateTime.utc(2026, 8, 20, 11),
      status: SessionStatus.inProgress,
      dirty: true,
    )..id = 9;
    sessions.rows[9] = local;

    remoteSessions.store['sess-1'] = WorkoutSession.create(
      uuid: 'sess-1',
      planId: 'plan-1',
      planDayId: 'day-1',
      planTitleSnapshot: 'draft',
      dayTitleSnapshot: 'remote-day',
      startedAt: DateTime.utc(2026, 8, 20, 10),
      updatedAt: DateTime.utc(2026, 8, 21, 9),
      status: SessionStatus.completed,
    );

    await SyncService(
      plans: _MemoryPlans(),
      sessions: sessions,
      remotePlans: _MemoryRemotePlans(),
      remoteSessions: remoteSessions,
    ).pull();

    final stored = await sessions.byUuid('sess-1');
    expect(stored!.id, 9);
    expect(stored.dayTitleSnapshot, 'remote-day');
    expect(stored.status, SessionStatus.completed);
    expect(stored.dirty, isFalse);
  });

  test('sync is a no-op when disabled', () async {
    final remotePlans = _MemoryRemotePlans();
    remotePlans.store['plan-1'] = _plan(
      uuid: 'plan-1',
      title: 'from-server',
      updatedAt: DateTime.utc(2026, 8, 21),
    );
    final plans = _MemoryPlans();
    final dirty = _plan(
      uuid: 'plan-2',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = dirty;

    await SyncService(
      plans: plans,
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
      enabled: false,
    ).sync();

    expect(await plans.byUuid('plan-1'), isNull);
    expect(dirty.dirty, isTrue);
  });

  test('sync skips a second call while one is already running', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var fetches = 0;
    final remotePlans = _LatchRemotePlans(() async {
      fetches += 1;
      if (!entered.isCompleted) entered.complete();
      await release.future;
      return const <WorkoutPlan>[];
    });

    final sync = SyncService(
      plans: _MemoryPlans(),
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
    );
    final first = sync.sync();
    await entered.future;
    await sync.sync();
    expect(fetches, 1);
    release.complete();
    await first;
    expect(fetches, 1);
  });
}

WorkoutPlan _plan({
  required String uuid,
  required String title,
  required DateTime updatedAt,
  bool dirty = false,
}) {
  return WorkoutPlan.create(
    uuid: uuid,
    dirty: dirty,
    title: title,
    source: PlanSource.created,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: updatedAt,
  );
}

class _LatchRemotePlans implements RemotePlanDataSource {
  _LatchRemotePlans(this._fetchAll);

  final Future<List<WorkoutPlan>> Function() _fetchAll;

  @override
  Future<List<WorkoutPlan>> fetchAll() => _fetchAll();

  @override
  Future<void> upsert(WorkoutPlan plan) async {}
}

class _MemoryRemotePlans implements RemotePlanDataSource {
  final store = <String, WorkoutPlan>{};

  @override
  Future<List<WorkoutPlan>> fetchAll() async => store.values.toList();

  @override
  Future<void> upsert(WorkoutPlan plan) async {
    store[plan.uuid] = plan;
  }
}

class _MemoryRemoteSessions implements RemoteSessionDataSource {
  final store = <String, WorkoutSession>{};

  @override
  Future<List<WorkoutSession>> fetchAll() async => store.values.toList();

  @override
  Future<void> upsert(WorkoutSession session) async {
    store[session.uuid] = session;
  }
}

class _MemoryPlans implements PlanRepository {
  final rows = <int, WorkoutPlan>{};
  var _seq = 1;

  @override
  Future<List<WorkoutPlan>> all() async {
    final list = rows.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<WorkoutPlan?> byId(int id) async => rows[id];

  @override
  Future<WorkoutPlan?> byUuid(String uuid) async {
    for (final plan in rows.values) {
      if (plan.uuid == uuid) return plan;
    }
    return null;
  }

  @override
  Future<int> count() async => rows.length;

  @override
  Future<bool> delete(int id) async => rows.remove(id) != null;

  @override
  Future<int> putSynced(WorkoutPlan plan) async {
    plan.dirty = false;
    if (plan.id == 0 || !rows.containsKey(plan.id)) {
      plan.id = _seq++;
    }
    rows[plan.id] = plan;
    return plan.id;
  }

  @override
  Future<int> save(WorkoutPlan plan) async {
    plan.dirty = true;
    plan.updatedAt = DateTime.now().toUtc();
    return putSynced(plan).then((id) {
      plan.dirty = true;
      return id;
    });
  }

  Future<int> saveKeepingTime(WorkoutPlan plan) async {
    plan.dirty = true;
    if (plan.id == 0) plan.id = _seq++;
    rows[plan.id] = plan;
    return plan.id;
  }

  @override
  Future<List<WorkoutPlan>> unsynced() async => [
        for (final plan in rows.values)
          if (plan.dirty) plan,
      ];

  @override
  Stream<void> watch({bool fireImmediately = false}) => const Stream.empty();
}

class _MemorySessions implements SessionRepository {
  final rows = <int, WorkoutSession>{};
  var _seq = 1;

  @override
  Future<WorkoutSession?> byId(int id) async => rows[id];

  @override
  Future<WorkoutSession?> byUuid(String uuid) async {
    for (final session in rows.values) {
      if (session.uuid == uuid) return session;
    }
    return null;
  }

  @override
  Future<List<WorkoutSession>> completedNewestFirst({String? planId}) async =>
      const [];

  @override
  Future<bool> delete(int id) async => rows.remove(id) != null;

  @override
  Future<List<WorkoutSession>> forCalendarDay(DateTime day) async => const [];

  @override
  Future<List<WorkoutSession>> forMonth(DateTime month) async => const [];

  @override
  Future<WorkoutSession?> inProgress() async => null;

  @override
  Future<WorkoutSession?> lastCompleted({String? planId}) async => null;

  @override
  Future<int> putSynced(WorkoutSession session) async {
    session.dirty = false;
    if (session.id == 0 || !rows.containsKey(session.id)) {
      session.id = _seq++;
    }
    rows[session.id] = session;
    return session.id;
  }

  @override
  Future<int> save(WorkoutSession session) async {
    session.dirty = true;
    session.updatedAt = DateTime.now().toUtc();
    return putSynced(session).then((id) {
      session.dirty = true;
      return id;
    });
  }

  @override
  Future<List<WorkoutSession>> unsynced() async => [
        for (final session in rows.values)
          if (session.dirty) session,
      ];

  @override
  Stream<void> watch({bool fireImmediately = false}) => const Stream.empty();
}
