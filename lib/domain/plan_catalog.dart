/// Stable goal identifiers stored on [WorkoutPlan.goalIds].
class PlanGoal {
  const PlanGoal({required this.id, required this.label});

  final String id;
  final String label;
}

/// Canonical training goals. Display labels are not persisted.
const planGoals = <PlanGoal>[
  PlanGoal(id: 'build-strength', label: 'Build strength'),
  PlanGoal(id: 'build-muscle', label: 'Build muscle'),
  PlanGoal(id: 'lose-weight', label: 'Lose weight'),
  PlanGoal(id: 'mobility', label: 'Mobility'),
  PlanGoal(id: 'general-fitness', label: 'General fitness'),
];

const planGoalIds = <String>[
  'build-strength',
  'build-muscle',
  'lose-weight',
  'mobility',
  'general-fitness',
];

/// Stable target-area identifiers stored on [ExercisePrescription.targetAreaIds].
class TargetArea {
  const TargetArea({required this.id, required this.label});

  final String id;
  final String label;
}

/// Canonical body-map taxonomy. Display labels are not persisted.
const targetAreas = <TargetArea>[
  TargetArea(id: 'chest', label: 'Chest'),
  TargetArea(id: 'triceps', label: 'Triceps'),
  TargetArea(id: 'biceps', label: 'Biceps'),
  TargetArea(id: 'front-shoulders', label: 'Front shoulders'),
  TargetArea(id: 'side-shoulders', label: 'Side shoulders'),
  TargetArea(id: 'rear-shoulders', label: 'Rear shoulders'),
  TargetArea(id: 'upper-traps', label: 'Upper traps'),
  TargetArea(id: 'forearms', label: 'Forearms'),
  TargetArea(id: 'lats', label: 'Lats'),
  TargetArea(id: 'upper-back', label: 'Upper back'),
  TargetArea(id: 'quads', label: 'Quads'),
  TargetArea(id: 'glutes', label: 'Glutes'),
  TargetArea(id: 'hamstrings', label: 'Hamstrings'),
  TargetArea(id: 'calves', label: 'Calves'),
  TargetArea(id: 'abs', label: 'Abs'),
  TargetArea(id: 'core', label: 'Core'),
  TargetArea(id: 'hips', label: 'Hips'),
  TargetArea(id: 'full-body', label: 'Full body'),
];

final _goalById = {for (final goal in planGoals) goal.id: goal};
final _areaById = {for (final area in targetAreas) area.id: area};

PlanGoal? planGoalById(String id) => _goalById[id];

TargetArea? targetAreaById(String id) => _areaById[id];

String planGoalLabel(String id) => planGoalById(id)?.label ?? id;

String targetAreaLabel(String id) => targetAreaById(id)?.label ?? id;

/// Keeps catalog/display order and drops unknown or duplicate ids.
List<String> canonicalizeGoalIds(Iterable<String> ids) {
  final seen = <String>{};
  final result = <String>[];
  for (final goal in planGoals) {
    for (final id in ids) {
      if (id == goal.id && seen.add(id)) {
        result.add(id);
      }
    }
  }
  return result;
}

/// Keeps catalog/display order and drops unknown or duplicate ids.
List<String> canonicalizeTargetAreaIds(Iterable<String> ids) {
  final seen = <String>{};
  final result = <String>[];
  for (final area in targetAreas) {
    for (final id in ids) {
      if (id == area.id && seen.add(id)) {
        result.add(id);
      }
    }
  }
  return result;
}

bool sameIdList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
