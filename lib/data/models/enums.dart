/// How a [WorkoutPlan] entered the local database.
enum PlanSource { imported, created }

/// A block is either one movement or a grouped superset.
enum BlockKind { single, superset }

/// Lifecycle of a [WorkoutSession]. At most one [inProgress] session exists.
enum SessionStatus { inProgress, completed, abandoned }

/// Progress grouping key: same trimmed, lowercased title rolls up across days.
String exerciseTitleKeyFor(String title) => title.trim().toLowerCase();
