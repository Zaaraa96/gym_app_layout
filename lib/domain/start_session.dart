import 'models/models.dart';
import 'session_lifecycle.dart';
import 'session_repository.dart';

/// What the user picked on a live-session conflict dialog.
enum LiveSessionChoice { resumeExisting, abandonAndStart, cancel }

/// Outcome of starting a day. Widgets render; they do not assemble logs.
sealed class StartSessionResult {
  const StartSessionResult();
}

final class StartSessionOpened extends StartSessionResult {
  const StartSessionOpened(this.session);

  final WorkoutSession session;
}

final class StartSessionCancelled extends StartSessionResult {
  const StartSessionCancelled();
}

final class StartSessionEmpty extends StartSessionResult {
  const StartSessionEmpty();
}

/// Start / resume / abandon a day. Dialogs stay in the UI; this decides.
class StartSession {
  StartSession(this._lifecycle, this._sessions);

  final SessionLifecycle _lifecycle;
  final SessionRepository _sessions;

  Future<StartSessionResult> run({
    required WorkoutPlan plan,
    required String planDayId,
    required Future<LiveSessionChoice> Function(WorkoutSession existing)
        onConflict,
    required Future<List<String>?> Function(List<CommonSection> sections)
        onCommons,
  }) async {
    PlanDay? day;
    for (final item in plan.days) {
      if (item.dayId == planDayId) {
        day = item;
        break;
      }
    }
    if (day == null) {
      throw ArgumentError.value(planDayId, 'planDayId', 'Day not on this plan');
    }

    final existing = await _sessions.inProgress();
    if (existing != null) {
      if (existing.planId == plan.uuid && existing.planDayId == day.dayId) {
        return StartSessionOpened(existing);
      }
      final choice = await onConflict(existing);
      switch (choice) {
        case LiveSessionChoice.cancel:
          return const StartSessionCancelled();
        case LiveSessionChoice.resumeExisting:
          return StartSessionOpened(existing);
        case LiveSessionChoice.abandonAndStart:
          await _lifecycle.abandonInProgress();
      }
    }

    var included = <String>[];
    if (plan.commonSections.isNotEmpty) {
      final chosen = await onCommons(plan.commonSections);
      if (chosen == null) return const StartSessionCancelled();
      included = chosen;
    }

    final logs = exerciseLogsForStart(
      day: day,
      commonSections: plan.commonSections,
      includedCommonSectionIds: included,
    );
    if (logs.isEmpty) return const StartSessionEmpty();

    final session = await _lifecycle.start(
      plan: plan,
      planDayId: day.dayId,
      includedCommonSectionIds: included,
    );
    return StartSessionOpened(session);
  }
}
