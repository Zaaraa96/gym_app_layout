import 'package:shared_preferences/shared_preferences.dart';

/// App-level workout reminder prefs (not per plan).
class ReminderPrefs {
  ReminderPrefs(this._prefs);

  static const enabledKey = 'reminder_enabled';
  static const hourKey = 'reminder_hour';
  static const minuteKey = 'reminder_minute';

  final SharedPreferences _prefs;

  static Future<ReminderPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderPrefs(prefs);
  }

  bool get enabled => _prefs.getBool(enabledKey) ?? false;

  /// Local time of day; default 07:00.
  TimeOfDayLocal get timeLocal {
    final hour = _prefs.getInt(hourKey) ?? 7;
    final minute = _prefs.getInt(minuteKey) ?? 0;
    return TimeOfDayLocal(hour: hour, minute: minute);
  }

  Future<void> setEnabled(bool value) => _prefs.setBool(enabledKey, value);

  Future<void> setTimeLocal(TimeOfDayLocal value) async {
    await _prefs.setInt(hourKey, value.hour);
    await _prefs.setInt(minuteKey, value.minute);
  }
}

class TimeOfDayLocal {
  const TimeOfDayLocal({required this.hour, required this.minute});

  final int hour;
  final int minute;

  String get label {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Whether a reminder should fire given Today's due workouts.
bool reminderShouldFire({
  required bool enabled,
  required int workoutDueCount,
}) =>
    enabled && workoutDueCount > 0;
