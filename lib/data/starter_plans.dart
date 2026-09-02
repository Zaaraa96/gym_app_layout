import 'package:flutter/services.dart';

import 'json_plan_importer.dart';
import '../domain/models/models.dart';
import '../domain/plan_repository.dart';

/// Bundled first-run programs. One tap writes a real [WorkoutPlan].
class StarterPlanSpec {
  const StarterPlanSpec({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.blurb,
    this.recommended = false,
  });

  final String id;
  final String assetPath;
  final String title;
  final String blurb;
  final bool recommended;
}

const starterFullBody = StarterPlanSpec(
  id: 'beginner-full-body',
  assetPath: 'assets/json/beginner-full-body.json',
  title: 'Beginner full body',
  blurb:
      'Three short days. Bodyweight first. Add weight when the sets feel easy.',
  recommended: true,
);

const starterTwoDay = StarterPlanSpec(
  id: 'beginner-two-day',
  assetPath: 'assets/json/beginner-two-day.json',
  title: 'Beginner 2-day',
  blurb: 'A and B only. Use this if you train about twice a week.',
);

const starterPlans = [starterFullBody, starterTwoDay];

/// Parses a bundled starter JSON into a new imported plan.
Future<WorkoutPlan> loadStarterPlan(
  StarterPlanSpec spec, {
  JsonPlanImporter importer = const JsonPlanImporter(),
  Future<String> Function(String assetPath)? loadAsset,
}) async {
  final loader = loadAsset ?? rootBundle.loadString;
  final source = await loader(spec.assetPath);
  return importer.import(source);
}

/// Saves the starter unless a plan with the same title is already stored.
///
/// Returns the existing plan in that case so tapping twice does not duplicate.
Future<WorkoutPlan> installStarterPlan(
  StarterPlanSpec spec, {
  required PlanRepository plans,
  JsonPlanImporter importer = const JsonPlanImporter(),
  Future<String> Function(String assetPath)? loadAsset,
}) async {
  for (final existing in await plans.all()) {
    if (existing.title == spec.title) return existing;
  }
  final plan = await loadStarterPlan(
    spec,
    importer: importer,
    loadAsset: loadAsset,
  );
  plan.id = await plans.save(plan);
  return plan;
}
