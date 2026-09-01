import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../data/models/models.dart';
import '../../data/session_lifecycle.dart';
import '../../data/session_repository.dart';
import '../../data/start_session.dart';
import 'live_workout_page.dart';

/// Opens the live logger for the session [uuid].
Future<void> openLiveSession(String sessionId) async {
  await Get.to(
    () => LiveWorkoutPage(sessionId: sessionId),
    routeName: AppRoutes.session,
  );
}

/// Start or resume a day. Asks about commons and an existing live session.
Future<void> startWorkout({
  required BuildContext context,
  required WorkoutPlan plan,
  required PlanDay day,
  StartSession? start,
}) async {
  final runner = start ??
      StartSession(
        Get.find<SessionLifecycle>(),
        Get.find<SessionRepository>(),
      );

  final result = await runner.run(
    plan: plan,
    planDayId: day.dayId,
    onConflict: (existing) => _askConflict(context, existing, day),
    onCommons: (_) => _askCommons(context, plan),
  );
  if (!context.mounted) return;

  switch (result) {
    case StartSessionOpened(:final session):
      await openLiveSession(session.uuid);
    case StartSessionCancelled():
      return;
    case StartSessionEmpty():
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turn on a section or add an exercise first.'),
        ),
      );
  }
}

Future<LiveSessionChoice> _askConflict(
  BuildContext context,
  WorkoutSession existing,
  PlanDay day,
) async {
  if (!context.mounted) return LiveSessionChoice.cancel;
  final action = await showDialog<_ConflictAction>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A workout is already in progress'),
      content: Text(
        'You still have "${existing.dayTitleSnapshot}" open. '
        'Resume it, or abandon it and start ${day.title}.',
      ),
      actions: [
        TextButton(
          key: const Key('resume-existing'),
          onPressed: () => Navigator.pop(context, _ConflictAction.resume),
          child: const Text('Resume existing'),
        ),
        TextButton(
          key: const Key('abandon-and-start'),
          onPressed: () => Navigator.pop(context, _ConflictAction.abandon),
          child: const Text('Abandon and start this day'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  return switch (action) {
    _ConflictAction.resume => LiveSessionChoice.resumeExisting,
    _ConflictAction.abandon => LiveSessionChoice.abandonAndStart,
    null => LiveSessionChoice.cancel,
  };
}

Future<List<String>?> _askCommons(BuildContext context, WorkoutPlan plan) {
  if (!context.mounted) return Future<List<String>?>.value();
  return showDialog<List<String>>(
    context: context,
    builder: (context) => _IncludeCommonsDialog(plan: plan),
  );
}

enum _ConflictAction { resume, abandon }

class _IncludeCommonsDialog extends StatefulWidget {
  const _IncludeCommonsDialog({required this.plan});

  final WorkoutPlan plan;

  @override
  State<_IncludeCommonsDialog> createState() => _IncludeCommonsDialogState();
}

class _IncludeCommonsDialogState extends State<_IncludeCommonsDialog> {
  late final Set<String> _on = {};

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return AlertDialog(
      title: const Text('Include today'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('These extras are off unless you turn them on.'),
            for (final section in plan.commonSections)
              SwitchListTile(
                key: Key('include-section-${section.sectionId}'),
                contentPadding: EdgeInsets.zero,
                title: Text(section.title),
                value: _on.contains(section.sectionId),
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      _on.add(section.sectionId);
                    } else {
                      _on.remove(section.sectionId);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-include'),
          onPressed: () => Navigator.pop(context, _on.toList()),
          child: const Text('Start'),
        ),
      ],
    );
  }
}
