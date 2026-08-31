import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/remote/entity_dto.dart';
import 'package:gym_app/data/remote/http_remote_plan_data_source.dart';
import 'package:gym_app/data/remote/http_remote_session_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET /plans maps DTO entities and skips non-objects', () async {
    final plan = _plan();
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://api.example/plans');
      return http.Response(
        jsonEncode([
          PlanDto.fromEntity(plan).toJson(),
          'skip-me',
          3,
        ]),
        200,
      );
    });

    final rows = await HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: client,
    ).fetchAll();

    expect(rows, hasLength(1));
    expect(rows.single.uuid, 'plan-uuid');
    expect(rows.single.title, 'plan 1');
    expect(rows.single.dirty, isFalse);
    expect(rows.single.id, 0);
  });

  test('GET /plans returns empty when the body is not a list', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'plans': []}), 200);
    });

    final rows = await HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: client,
    ).fetchAll();
    expect(rows, isEmpty);
  });

  test('GET /plans throws on a non-2xx status', () async {
    final client = MockClient((request) async {
      return http.Response('nope', 500);
    });

    await expectLater(
      HttpRemotePlanDataSource(
        baseUrl: 'https://api.example',
        client: client,
      ).fetchAll(),
      throwsA(
        isA<RemoteHttpException>().having(
          (e) => e.message,
          'message',
          'GET /plans failed (500)',
        ),
      ),
    );
  });

  test('PUT /plans uses the uuid path and omits the Isar row id', () async {
    http.Request? captured;
    final plan = _plan()..id = 99;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('', 204);
    });

    await HttpRemotePlanDataSource(
      baseUrl: 'https://api.example',
      client: client,
    ).upsert(plan);

    expect(captured, isNotNull);
    expect(captured!.method, 'PUT');
    expect(captured!.url.toString(), 'https://api.example/plans/plan-uuid');
    expect(captured!.headers['Content-Type'], contains('application/json'));
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['id'], 'plan-uuid');
    expect(body.containsKey('dirty'), isFalse);
    expect(body.values, isNot(contains(99)));
  });

  test('GET /sessions maps session DTOs', () async {
    final session = _session();
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.example/sessions');
      return http.Response(
        jsonEncode([SessionDto.fromEntity(session).toJson()]),
        200,
      );
    });

    final rows = await HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: client,
    ).fetchAll();
    expect(rows.single.uuid, 'sess-uuid');
    expect(rows.single.planId, 'plan-uuid');
    expect(rows.single.status, SessionStatus.completed);
    expect(rows.single.dirty, isFalse);
  });

  test('PUT /sessions uses the uuid path and GET /sessions throws on 404',
      () async {
    http.Request? captured;
    final session = _session()..id = 4;
    final client = MockClient((request) async {
      if (request.method == 'PUT') {
        captured = request;
        return http.Response('', 201);
      }
      return http.Response('missing', 404);
    });
    final source = HttpRemoteSessionDataSource(
      baseUrl: 'https://api.example',
      client: client,
    );

    await source.upsert(session);
    expect(captured!.url.toString(), 'https://api.example/sessions/sess-uuid');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['id'], 'sess-uuid');
    expect(body['planId'], 'plan-uuid');
    expect(body.values, isNot(contains(4)));

    await expectLater(
      source.fetchAll(),
      throwsA(
        isA<RemoteHttpException>().having(
          (e) => e.message,
          'message',
          'GET /sessions failed (404)',
        ),
      ),
    );
  });
}

WorkoutPlan _plan() {
  return WorkoutPlan.create(
    uuid: 'plan-uuid',
    title: 'plan 1',
    source: PlanSource.created,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
  );
}

WorkoutSession _session() {
  return WorkoutSession.create(
    uuid: 'sess-uuid',
    planId: 'plan-uuid',
    planDayId: 'day-1',
    planTitleSnapshot: 'plan 1',
    dayTitleSnapshot: 'day 1',
    startedAt: DateTime.utc(2026, 8, 15, 10),
    updatedAt: DateTime.utc(2026, 8, 15, 11),
    status: SessionStatus.completed,
  );
}
