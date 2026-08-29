import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../data/models/models.dart';
import '../../data/session_lifecycle.dart';
import '../../data/session_repository.dart';
import 'live_workout_page.dart';

/// Opens the live logger for [sessionId].
Future<void> openLiveSession(int sessionId) async {
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
}) async {
  final sessions = Get.find<SessionRepository>();
  final lifecycle = Get.find<SessionLifecycle>();

  final existing = await sessions.inProgress();
  if (!context.mounted) return;
  if (existing != null) {
    if (existing.planId == plan.uuid && existing.planDayId == day.dayId) {
      await openLiveSession(existing.id);
      return;
    }
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
    if (!context.mounted) return;
    if (action == null) return;
    if (action == _ConflictAction.resume) {
      await openLiveSession(existing.id);
      return;
    }
    await lifecycle.abandonInProgress();
    if (!context.mounted) return;
  }

  var included = <String>[];
  if (plan.commonSections.isNotEmpty) {
    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (context) => _IncludeCommonsDialog(plan: plan),
    );
    if (!context.mounted) return;
    if (chosen == null) return;
    included = chosen;
  }

  final logs = exerciseLogsForStart(
    day: day,
    commonSections: plan.commonSections,
    includedCommonSectionIds: included,
  );
  if (logs.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Turn on a section or add an exercise first.'),
      ),
    );
    return;
  }

  final session = await lifecycle.start(
    plan: plan,
    planDayId: day.dayId,
    includedCommonSectionIds: included,
  );
  if (!context.mounted) return;
  await openLiveSession(session.id);
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
