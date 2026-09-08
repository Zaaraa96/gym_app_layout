/// How a [WorkoutPlan] entered the local database.
enum PlanSource { imported, created }

/// Whether a [WorkoutPlan] is still being built or is ready to train.
///
/// Separate from [PlanSource]: a created plan can be a draft, and an imported
/// plan is active.
///
/// [active] is first so a missing Isar byte (rows written before this field)
/// deserializes as startable. Isar stores `status.index` and falls back to
/// `PlanStatus.values.first` when the property is absent.
enum PlanStatus { active, draft }

/// A block is either one movement or a grouped superset.
enum BlockKind { single, superset }

/// How the exercise editor presents a block.
enum ExerciseEditorMode { single, superset }

/// Exactly one of reps or duration is stored on a prescription.
enum PrescriptionType { reps, timed }

/// Whether a catalog movement shipped with the app or was created locally.
enum CatalogOrigin { bundled, user }

/// Lifecycle of a [WorkoutSession]. At most one [inProgress] session exists.
enum SessionStatus { inProgress, completed, abandoned }

/// Progress grouping key: same trimmed, lowercased title rolls up across days.
String exerciseTitleKeyFor(String title) => title.trim().toLowerCase();

/// Where an exercise block's preview media comes from.
enum ExerciseMediaSource { none, asset, gallery, network }

/// Preview media type for an exercise block.
enum ExerciseMediaKind { unknown, svg, image, gif, video }
