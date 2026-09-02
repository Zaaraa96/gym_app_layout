import '../../domain/models/workout_session.dart';

/// HTTP access for sessions. Not registered as [SessionRepository].
abstract class RemoteSessionDataSource {
  Future<List<WorkoutSession>> fetchAll();

  Future<void> upsert(WorkoutSession session);
}

/// Used when no API base URL is configured.
class NoopRemoteSessionDataSource implements RemoteSessionDataSource {
  const NoopRemoteSessionDataSource();

  @override
  Future<List<WorkoutSession>> fetchAll() async => const [];

  @override
  Future<void> upsert(WorkoutSession session) async {}
}
