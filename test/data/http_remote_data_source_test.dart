import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/remote/entity_dto.dart';
import 'package:gym_app/data/remote/http_remote_plan_data_source.dart';
import 'package:gym_app/data/remote/http_remote_session_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final plan = WorkoutPlan.create(
    uuid: 'plan-uuid',
    title: 'push',
    source: PlanSource.created,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
  )..id = 99;

  final session = WorkoutSession.create(
    uuid: 'sess-uuid',
    planId: 'plan-uuid',
    planDayId: 'day-1',
    planTitleSnapshot: 'push',
    dayTitleSnapshot: 'day 1',
    startedAt: DateTime.utc(2026, 8, 15, 10),
    updatedAt: DateTime.utc(2026, 8, 15, 11),
    status: SessionStatus.completed,
  )..id = 7;

  test('GET /plans maps objects, skips non-maps, and treats a non-list as empty',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://api.example/plans');
      return http.Response(
        jsonEncode([PlanDto.fromEntity(plan).toJson(), 42]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final source = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: client,
    );
    final fetched = await source.fetchAll();
    expect(fetched, hasLength(1));
    expect(fetched.single.uuid, 'plan-uuid');
    expect(fetched.single.dirty, isFalse);
    expect(fetched.single.id, isNot(99));

    final emptySource = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: MockClient(
        (_) async => http.Response('{}', 200),
      ),
    );
    expect(await emptySource.fetchAll(), isEmpty);
  });

  test('PUT /plans/{uuid} sends the DTO and throws on a non-2xx', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('', 204);
    });
    final source = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: client,
    );
    await source.upsert(plan);
    expect(captured!.method, 'PUT');
    expect(captured!.url.toString(), 'https://api.example/plans/plan-uuid');
    expect(captured!.headers['Content-Type'], 'application/json');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['id'], 'plan-uuid');
    expect(body.containsKey('dirty'), isFalse);
    expect(body.values, isNot(contains(99)));

    final failing = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((_) async => http.Response('no', 409)),
    );
    await expectLater(
      failing.upsert(plan),
      throwsA(
        isA<RemoteHttpException>().having(
          (e) => e.message,
          'message',
          contains('PUT /plans/plan-uuid failed (409)'),
        ),
      ),
    );
  });

  test('GET /plans throws RemoteHttpException on a 5xx', () async {
    final source = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((_) async => http.Response('down', 503)),
    );
    await expectLater(
      source.fetchAll(),
      throwsA(
        isA<RemoteHttpException>().having(
          (e) => e.toString(),
          'toString',
          contains('GET /plans failed (503)'),
        ),
      ),
    );
  });

  test('session fetch and upsert use /sessions and the session uuid', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        expect(request.url.path, '/sessions');
        return http.Response(
          jsonEncode([SessionDto.fromEntity(session).toJson()]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(request.method, 'PUT');
      expect(request.url.path, '/sessions/sess-uuid');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['id'], 'sess-uuid');
      expect(body['planId'], 'plan-uuid');
      expect(body.values, isNot(contains(7)));
      return http.Response('', 200);
    });
    final source = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: client,
    );
    final fetched = await source.fetchAll();
    expect(fetched.single.uuid, 'sess-uuid');
    expect(fetched.single.planId, 'plan-uuid');
    await source.upsert(session);

    final failing = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((_) async => http.Response('', 500)),
    );
    await expectLater(
      failing.fetchAll(),
      throwsA(isA<RemoteHttpException>()),
    );
    await expectLater(
      failing.upsert(session),
      throwsA(
        isA<RemoteHttpException>().having(
          (e) => e.message,
          'message',
          contains('PUT /sessions/sess-uuid failed (500)'),
        ),
      ),
    );
  });

  test('GET does not treat invalid JSON or timeouts as an empty catalog',
      () async {
    final invalid = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((_) async => http.Response('not-json', 200)),
    );
    await expectLater(invalid.fetchAll(), throwsFormatException);

    final timedOut = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: MockClient(
        (_) async => throw TimeoutException('GET /plans timed out'),
      ),
    );
    await expectLater(timedOut.fetchAll(), throwsA(isA<TimeoutException>()));

    final disconnected = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: MockClient(
        (_) async => throw http.ClientException('connection failed'),
      ),
    );
    await expectLater(
      disconnected.fetchAll(),
      throwsA(isA<http.ClientException>()),
    );
    await expectLater(
      disconnected.upsert(session),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('GET /sessions skips non-maps and treats a non-list as empty', () async {
    final source = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode([SessionDto.fromEntity(session).toJson(), 'skip-me']),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final fetched = await source.fetchAll();
    expect(fetched, hasLength(1));
    expect(fetched.single.uuid, 'sess-uuid');
    expect(fetched.single.id, isNot(7));

    final emptySource = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((_) async => http.Response('true', 200)),
    );
    expect(await emptySource.fetchAll(), isEmpty);
  });

  test('PUT 201 is success and empty endedAt is not treated as a parse error',
      () async {
    http.Request? captured;
    final created = HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: MockClient((request) async {
        captured = request;
        return http.Response('', 201);
      }),
    );
    await created.upsert(plan);
    expect(captured!.method, 'PUT');
    expect(captured!.url.path, '/plans/plan-uuid');

    final sessionJson = SessionDto.fromEntity(session).toJson();
    sessionJson['endedAt'] = '';
    sessionJson['exerciseLogs'] = [
      {
        'prescriptionId': 'p-1',
        'blockId': 'block-1',
        'blockKind': 'single',
        'fromCommonSection': false,
        'exerciseTitle': 'plank',
        'exerciseTitleKey': 'plank',
        'prescribedSets': 1,
        'prescribedDurationSeconds': 30,
        'sets': [
          {
            'setIndex': 1,
            'completedAt': '2026-08-15T10:05:00.000Z',
            'durationSeconds': 28,
          },
        ],
      },
    ];
    final sessions = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([sessionJson]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final fetched = await sessions.fetchAll();
    expect(fetched, hasLength(1));
    expect(fetched.single.endedAt, isNull);
    expect(fetched.single.exerciseLogs.single.sets.single.durationSeconds, 28);
    expect(fetched.single.exerciseLogs.single.prescribedDurationSeconds, 30);
  });
}
