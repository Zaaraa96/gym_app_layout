import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/app_ports.dart';
import '../../domain/reminder_prefs.dart';

/// Simple Workout reminder toggle + time (fires only when a workout is due).
Future<void> showReminderSettingsSheet(
  BuildContext context, {
  required AppPorts ports,
  required int workoutDueCount,
}) async {
  ReminderPrefs prefs;
  try {
    prefs = await ReminderPrefs.load();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open reminder settings.')),
    );
    return;
  }
  if (!context.mounted) return;

  var enabled = prefs.enabled;
  var time = prefs.timeLocal;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModal) {
          final wouldFire = reminderShouldFire(
            enabled: enabled,
            workoutDueCount: workoutDueCount,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Workout reminder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Local reminder only. Fires when Today has at least one workout due — never for Rest-only days.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SwitchListTile(
                  key: const Key('reminder-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable reminder'),
                  value: enabled,
                  onChanged: (value) async {
                    enabled = value;
                    await prefs.setEnabled(value);
                    setModal(() {});
                  },
                ),
                ListTile(
                  key: const Key('reminder-time'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Time'),
                  subtitle: Text(time.label),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          TimeOfDay(hour: time.hour, minute: time.minute),
                    );
                    if (picked == null) return;
                    time = TimeOfDayLocal(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                    await prefs.setTimeLocal(time);
                    setModal(() {});
                  },
                ),
                Text(
                  wouldFire
                      ? 'Today has a workout due — reminder would fire at ${time.label}.'
                      : enabled
                          ? 'No workout due today — reminder stays quiet.'
                          : 'Reminder is off.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Optional GetX registration for tests that want a shared prefs instance.
Future<void> ensureReminderPrefs() async {
  if (Get.isRegistered<ReminderPrefs>()) return;
  try {
    Get.put(await ReminderPrefs.load(), permanent: true);
  } catch (_) {
    // SharedPreferences may be unavailable in some hosts.
  }
}
