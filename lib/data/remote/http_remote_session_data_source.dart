import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/workout_session.dart';
import 'entity_dto.dart';
import 'http_remote_plan_data_source.dart';
import 'remote_session_data_source.dart';

/// REST [RemoteSessionDataSource]. JSON bodies are [SessionDto], never `@collection`.
class HttpRemoteSessionDataSource implements RemoteSessionDataSource {
  HttpRemoteSessionDataSource({
    required this.baseUrl,
    required http.Client client,
  }) : _client = client;

  final String baseUrl;
  final http.Client _client;

  Uri get _sessions => Uri.parse('$baseUrl/sessions');

  @override
  Future<List<WorkoutSession>> fetchAll() async {
    final response = await _client.get(_sessions);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteHttpException(
          'GET /sessions failed (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final list = decoded is List ? decoded : const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          SessionDto.fromJson(item).toEntity()
        else if (item is Map)
          SessionDto.fromJson(Map<String, dynamic>.from(item)).toEntity(),
    ];
  }

  @override
  Future<void> upsert(WorkoutSession session) async {
    final uri = Uri.parse('$baseUrl/sessions/${session.uuid}');
    final response = await _client.put(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(SessionDto.fromEntity(session).toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteHttpException(
        'PUT /sessions/${session.uuid} failed (${response.statusCode})',
      );
    }
  }
}
