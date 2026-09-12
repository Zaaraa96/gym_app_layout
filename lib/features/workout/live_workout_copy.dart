/// Companion copy for the live logger (see docs/live-logger-comfort.md).
abstract final class LiveWorkoutCopy {
  static const leaveReassurance =
      'Leaving keeps this workout — Continue on Plans.';

  static const saveSetPrompt = 'Done with this set? Save it.';
  static const saveSet = 'Save set';
  static const bodyweightHint = 'Bodyweight is fine — leave weight blank.';

  static const ratePrompt = 'How did that feel?';
  static const skipRating = 'Skip for now';

  static const restBreathe = 'Breathe.';
  static const imReady = "I'm ready";

  static const ratedNext = 'This one is saved. Next up is below.';

  static const workoutComplete = 'Workout complete';
  static const niceWork = 'Nice work.';
  static const discarded = 'Workout discarded';
  static const discardedDetail =
      'This session will not show on the month view.';

  static const rateLabels = <int, String>{
    1: 'Easy',
    2: 'Light',
    3: 'Solid',
    4: 'Hard',
    5: 'Brutal',
  };

  static String yourTurn(String title) => 'Your turn: $title';

  static String thenPartner(String title) => 'then $title';

  static String nextUp(String title) => 'Next: $title';

  static String rateWhenReady(String title) =>
      'When you’re ready, how did $title feel?';

  /// Short beat before the ended screen, based on the last rating (or skip).
  static String sessionDoneBeat(int? difficulty) {
    switch (difficulty) {
      case 1:
        return 'That felt easy — nice.';
      case 2:
        return 'Under control. Session done.';
      case 3:
        return 'Nice. Session done.';
      case 4:
        return 'Hard work. You showed up.';
      case 5:
        return 'Brutal. And you finished.';
      default:
        return 'Saved. Session done.';
    }
  }
}
