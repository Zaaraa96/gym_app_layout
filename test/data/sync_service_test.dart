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
    expect((await plans.byUuid('plan-1'))!.id, 1);
    expect((await plans.byUuid('plan-2'))!.title, 'from-server');
    expect((await plans.byUuid('plan-2'))!.dirty, isFalse);
    expect(await plans.count(), 2);
  });

  test('pull overwrites when remote is newer or tied and keeps the Isar id',
      () async {
    final plans = _MemoryPlans();
    final sessions = _MemorySessions();
    final remotePlans = _MemoryRemotePlans();
    final remoteSessions = _MemoryRemoteSessions();

    final localPlan = _plan(
      uuid: 'plan-1',
      title: 'local-old',
      updatedAt: DateTime.utc(2026, 8, 10),
    )..id = 42;
    await plans.putSynced(localPlan);

    remotePlans.store['plan-1'] = _plan(
      uuid: 'plan-1',
      title: 'remote-new',
      updatedAt: DateTime.utc(2026, 8, 10),
    );

    final localSession = _session(
      uuid: 'sess-1',
      planId: 'plan-1',
      title: 'local-session',
      updatedAt: DateTime.utc(2026, 8, 11, 8),
    )..id = 7;
    await sessions.putSynced(localSession);

    remoteSessions.store['sess-1'] = _session(
      uuid: 'sess-1',
      planId: 'plan-1',
      title: 'remote-session',
      updatedAt: DateTime.utc(2026, 8, 11, 9),
    );

    await SyncService(
      plans: plans,
      sessions: sessions,
      remotePlans: remotePlans,
      remoteSessions: remoteSessions,
    ).pull();

    expect(await plans.count(), 1);
    expect((await plans.byId(42))!.title, 'remote-new');
    expect((await plans.byId(42))!.dirty, isFalse);
    expect((await sessions.byId(7))!.planTitleSnapshot, 'remote-session');
    expect((await sessions.byUuid('sess-1'))!.id, 7);
    expect((await sessions.byId(7))!.dirty, isFalse);
  });

  test('pull keeps a newer local session', () async {
    final sessions = _MemorySessions();
    final remoteSessions = _MemoryRemoteSessions();
    final local = _session(
      uuid: 'sess-1',
      planId: 'plan-1',
      title: 'local-newer',
      updatedAt: DateTime.utc(2026, 8, 20),
    )..id = 3;
    await sessions.putSynced(local);
    local.dirty = true;
    await sessions.saveKeepingTime(local);

    remoteSessions.store['sess-1'] = _session(
      uuid: 'sess-1',
      planId: 'plan-1',
      title: 'remote-old',
      updatedAt: DateTime.utc(2026, 8, 10),
    );

    await SyncService(
      plans: _MemoryPlans(),
      sessions: sessions,
      remotePlans: _MemoryRemotePlans(),
      remoteSessions: remoteSessions,
    ).pull();

    expect((await sessions.byId(3))!.planTitleSnapshot, 'local-newer');
    expect((await sessions.byId(3))!.dirty, isTrue);
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

  test('push is a no-op when offline even if called directly', () async {
    final plans = _MemoryPlans();
    final remotePlans = _MemoryRemotePlans();
    final plan = _plan(
      uuid: 'plan-1',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = plan;

    await SyncService(
      plans: plans,
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
      isOnline: () async => false,
    ).push();

    expect(remotePlans.store, isEmpty);
    expect(plan.dirty, isTrue);
  });

  test('disabled sync never pulls or pushes', () async {
    final plans = _MemoryPlans();
    final remotePlans = _MemoryRemotePlans();
    final plan = _plan(
      uuid: 'plan-1',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = plan;
    remotePlans.store['plan-2'] = _plan(
      uuid: 'plan-2',
      title: 'from-server',
      updatedAt: DateTime.utc(2026, 8, 21),
    );

    final sync = SyncService(
      plans: plans,
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
      enabled: false,
    );
    await sync.sync();
    await sync.pull();
    await sync.push();

    expect(await plans.byUuid('plan-2'), isNull);
    expect(plan.dirty, isTrue);
  });

  test('sync pulls remote rows then flushes dirty local rows', () async {
    final plans = _MemoryPlans();
    final remotePlans = _MemoryRemotePlans();
    final local = _plan(
      uuid: 'plan-local',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = local;
    remotePlans.store['plan-remote'] = _plan(
      uuid: 'plan-remote',
      title: 'from-server',
      updatedAt: DateTime.utc(2026, 8, 21),
    );

    await SyncService(
      plans: plans,
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
    ).sync();

    expect((await plans.byUuid('plan-remote'))!.title, 'from-server');
    expect(remotePlans.store['plan-local']!.title, 'draft');
    expect((await plans.byUuid('plan-local'))!.dirty, isFalse);
  });

  test('sync ignores a second call while the first is still running', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    final remotePlans = _GateRemotePlans(onFetch: started, gate: gate);
    final sync = SyncService(
      plans: _MemoryPlans(),
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
    );

    final first = sync.sync();
    await started.future;
    final second = sync.sync();
    await second;
    expect(remotePlans.fetchCount, 1);

    gate.complete();
    await first;
    expect(remotePlans.fetchCount, 1);
  });

  test('a failed sync unsticks the running flag so a later sync can run',
      () async {
    final plans = _MemoryPlans();
    final remotePlans = _FailOnceRemotePlans(
      after: _plan(
        uuid: 'plan-2',
        title: 'from-server',
        updatedAt: DateTime.utc(2026, 8, 21),
      ),
    );

    final sync = SyncService(
      plans: plans,
      sessions: _MemorySessions(),
      remotePlans: remotePlans,
      remoteSessions: _MemoryRemoteSessions(),
    );

    await expectLater(sync.sync(), throwsA(isA<StateError>()));
    expect(await plans.byUuid('plan-2'), isNull);
    expect(remotePlans.fetchCount, 1);

    await sync.sync();
    expect(remotePlans.fetchCount, 2);
    expect((await plans.byUuid('plan-2'))!.title, 'from-server');
    expect((await plans.byUuid('plan-2'))!.dirty, isFalse);
  });

  test('push that fails on a session still keeps the flushed plan clean',
      () async {
    final plans = _MemoryPlans();
    final sessions = _MemorySessions();
    final remotePlans = _MemoryRemotePlans();
    final plan = _plan(
      uuid: 'plan-1',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = plan;
    final session = _session(
      uuid: 'sess-1',
      planId: 'plan-1',
      title: 'draft-session',
      updatedAt: DateTime.utc(2026, 8, 20, 11),
      dirty: true,
    )..id = 3;
    sessions.rows[3] = session;

    await expectLater(
      SyncService(
        plans: plans,
        sessions: sessions,
        remotePlans: remotePlans,
        remoteSessions: _FailingRemoteSessions(),
      ).push(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'session write failed',
        ),
      ),
    );

    expect(plan.dirty, isFalse);
    expect(remotePlans.store['plan-1']!.title, 'draft');
    expect(session.dirty, isTrue);
    expect((await sessions.unsynced()).map((row) => row.id), [3]);
  });

  test('push keeps dirty rows when a remote write fails', () async {
    final plans = _MemoryPlans();
    final sessions = _MemorySessions();
    final remoteSessions = _MemoryRemoteSessions();
    final plan = _plan(
      uuid: 'plan-1',
      title: 'draft',
      updatedAt: DateTime.utc(2026, 8, 20),
      dirty: true,
    )..id = 1;
    plans.rows[1] = plan;
    final session = _session(
      uuid: 'sess-1',
      planId: 'plan-1',
      title: 'draft-session',
      updatedAt: DateTime.utc(2026, 8, 20, 11),
      dirty: true,
    )..id = 3;
    sessions.rows[3] = session;

    await expectLater(
      SyncService(
        plans: plans,
        sessions: sessions,
        remotePlans: _FailingRemotePlans(),
        remoteSessions: remoteSessions,
      ).push(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'remote write failed',
        ),
      ),
    );

    expect(plan.dirty, isTrue);
    expect(session.dirty, isTrue);
    expect((await plans.unsynced()).map((row) => row.id), [1]);
    expect((await sessions.unsynced()).map((row) => row.id), [3]);
    expect(remoteSessions.store, isEmpty);
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

WorkoutSession _session({
  required String uuid,
  required String planId,
  required String title,
  required DateTime updatedAt,
  bool dirty = false,
}) {
  return WorkoutSession.create(
    uuid: uuid,
    dirty: dirty,
    planId: planId,
    planDayId: 'day-1',
    planTitleSnapshot: title,
    dayTitleSnapshot: 'day 1',
    startedAt: DateTime.utc(2026, 8, 10),
    updatedAt: updatedAt,
    status: SessionStatus.completed,
  );
}

class _GateRemotePlans implements RemotePlanDataSource {
  _GateRemotePlans({required this.onFetch, required this.gate});

  final Completer<void> onFetch;
  final Completer<void> gate;
  var fetchCount = 0;

  @override
  Future<List<WorkoutPlan>> fetchAll() async {
    fetchCount++;
    if (!onFetch.isCompleted) onFetch.complete();
    await gate.future;
    return const [];
  }

  @override
  Future<void> upsert(WorkoutPlan plan) async {}
}

class _FailingRemotePlans implements RemotePlanDataSource {
  @override
  Future<List<WorkoutPlan>> fetchAll() async => const [];

  @override
  Future<void> upsert(WorkoutPlan plan) async {
    throw StateError('remote write failed');
  }
}

class _FailOnceRemotePlans implements RemotePlanDataSource {
  _FailOnceRemotePlans({this.after});

  final WorkoutPlan? after;
  var fetchCount = 0;

  @override
  Future<List<WorkoutPlan>> fetchAll() async {
    fetchCount++;
    if (fetchCount == 1) throw StateError('network');
    return after == null ? const [] : [after!];
  }

  @override
  Future<void> upsert(WorkoutPlan plan) async {}
}

class _FailingRemoteSessions implements RemoteSessionDataSource {
  @override
  Future<List<WorkoutSession>> fetchAll() async => const [];

  @override
  Future<void> upsert(WorkoutSession session) async {
    throw StateError('session write failed');
  }
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
    plan.id = _assignId(plan.id);
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
    plan.id = _assignId(plan.id);
    rows[plan.id] = plan;
    return plan.id;
  }

  int _assignId(int current) {
    if (current > 0) {
      if (current >= _seq) _seq = current + 1;
      return current;
    }
    while (rows.containsKey(_seq)) {
      _seq++;
    }
    return _seq++;
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
    session.id = _assignId(session.id);
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

  Future<int> saveKeepingTime(WorkoutSession session) async {
    session.dirty = true;
    session.id = _assignId(session.id);
    rows[session.id] = session;
    return session.id;
  }

  int _assignId(int current) {
    if (current > 0) {
      if (current >= _seq) _seq = current + 1;
      return current;
    }
    while (rows.containsKey(_seq)) {
      _seq++;
    }
    return _seq++;
  }

  @override
  Future<List<WorkoutSession>> unsynced() async => [
        for (final session in rows.values)
          if (session.dirty) session,
      ];

  @override
  Stream<void> watch({bool fireImmediately = false}) => const Stream.empty();
}
