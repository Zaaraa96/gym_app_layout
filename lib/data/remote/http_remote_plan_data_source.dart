import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/workout_plan.dart';
import 'entity_dto.dart';
import 'remote_plan_data_source.dart';

/// REST [RemotePlanDataSource]. JSON bodies are [PlanDto], never `@collection`.
class HttpRemotePlanDataSource implements RemotePlanDataSource {
  HttpRemotePlanDataSource({
    required this.baseUrl,
    required http.Client client,
  }) : _client = client;

  final String baseUrl;
  final http.Client _client;

  Uri get _plans => Uri.parse('$baseUrl/plans');

  @override
  Future<List<WorkoutPlan>> fetchAll() async {
    final response = await _client.get(_plans);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteHttpException('GET /plans failed (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final list = decoded is List ? decoded : const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          PlanDto.fromJson(item).toEntity()
        else if (item is Map)
          PlanDto.fromJson(Map<String, dynamic>.from(item)).toEntity(),
    ];
  }

  @override
  Future<void> upsert(WorkoutPlan plan) async {
    final uri = Uri.parse('$baseUrl/plans/${plan.uuid}');
    final response = await _client.put(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(PlanDto.fromEntity(plan).toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteHttpException(
        'PUT /plans/${plan.uuid} failed (${response.statusCode})',
      );
    }
  }
}

class RemoteHttpException implements Exception {
  RemoteHttpException(this.message);

  final String message;

  @override
  String toString() => message;
}
