/// A recoverable problem found while reading a plan package or JSON file.
///
/// The importer keeps going and the Create plan screen shows these so the
/// user can fix the draft.
class PlanImportIssue {
  const PlanImportIssue({
    required this.code,
    required this.message,
    this.stepKey,
    this.exerciseTitle,
  });

  /// Stable machine key, e.g. `syntax`, `missing-media`, `unknown-block`.
  final String code;

  /// Copy that is safe to show in the UI.
  final String message;

  /// `details`, a day id, or `review` — same keys as the plan builder steps.
  final String? stepKey;

  /// Optional movement name so Review can say which clip failed.
  final String? exerciseTitle;
}
