import '../domain/models/schedule.dart';

/// Reads and writes [PlanDaySkip] records.
abstract class SkipRepository {
  Future<List<PlanDaySkip>> all();

  Future<List<PlanDaySkip>> forPlan(String planId);

  Future<int> save(PlanDaySkip skip);

  Future<bool> delete(int id);

  /// Removes every skip for [planId] (used when restarting a Run-once cycle).
  Future<void> deleteForPlan(String planId);

  Stream<void> watch({bool fireImmediately = false});
}
