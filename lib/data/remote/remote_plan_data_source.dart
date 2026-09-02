import '../../domain/models/workout_plan.dart';

/// HTTP access for plans. Not registered as [PlanRepository].
abstract class RemotePlanDataSource {
  Future<List<WorkoutPlan>> fetchAll();

  Future<void> upsert(WorkoutPlan plan);
}

/// Used when no API base URL is configured.
class NoopRemotePlanDataSource implements RemotePlanDataSource {
  const NoopRemotePlanDataSource();

  @override
  Future<List<WorkoutPlan>> fetchAll() async => const [];

  @override
  Future<void> upsert(WorkoutPlan plan) async {}
}
