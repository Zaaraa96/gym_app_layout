import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../data/session_repository.dart';
import 'progress_format.dart';
import 'progress_service.dart';

/// Home-shell Month tab: calendar, dots, and per-exercise trends.
class MonthTab extends StatefulWidget {
  const MonthTab({super.key, this.now});

  /// Visible month defaults to this instant (UTC). Tests pass a fixed clock.
  final DateTime? now;

  @override
  State<MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<MonthTab> {
  final SessionRepository _sessions = Get.find<SessionRepository>();
  final ProgressService _progress = const ProgressService();

  late DateTime _month;
  MonthProgress? _data;
  bool _loading = true;
  String? _error;
  int _loadId = 0;
  StreamSubscription<void>? _watch;

  @override
  void initState() {
    super.initState();
    final clock = (widget.now ?? DateTime.now()).toUtc();
    _month = DateTime.utc(clock.year, clock.month);
    _load();
    _watch = _sessions.watch().listen((_) => _load());
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final data = await _progress.loadMonth(
        sessions: _sessions,
        month: _month,
      );
      if (!mounted || id != _loadId) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = 'Could not load this month.';
        }
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime.utc(_month.year, _month.month + delta);
      _loading = true;
    });
    _load();
  }

  Future<void> _openDay(DateTime day) async {
    final sessions = await _sessions.forCalendarDay(day);
    if (!mounted) return;
    if (sessions.length == 1) {
      Get.toNamed(AppRoutes.sessionLog, arguments: sessions.single.uuid);
      return;
    }
    Get.toNamed(AppRoutes.dayLog, arguments: day);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return AppLoadError(message: _error!, onRetry: _retry);
    }
    final data = _data!;
    final workoutDays = {
      for (final day in data.daysWithWorkouts) day.day,
    };

    return ListView(
      key: const Key('month-tab'),
      children: [
        _MonthHeader(
          title: formatMonthTitle(_month),
          onPrevious: () => _shiftMonth(-1),
          onNext: () => _shiftMonth(1),
        ),
        const SizedBox(height: 8),
        _MonthCalendar(
          month: _month,
          workoutDays: workoutDays,
          today: (widget.now ?? DateTime.now()).toUtc(),
          onDayTap: _openDay,
        ),
        const SizedBox(height: 16),
        if (data.isEmpty)
          const AppText(
            'No workouts this month.',
            style: subtitleTextStyle,
            textAlign: TextAlign.center,
          )
        else ...[
          const AppText('This month', style: dataTextStyle),
          const SizedBox(height: 8),
          for (final row in data.exercises) _ExerciseTrendTile(row: row),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('month-prev'),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: AppText(
            title,
            style: titleTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          key: const Key('month-next'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.workoutDays,
    required this.today,
    required this.onDayTap,
  });

  final DateTime month;
  final Set<int> workoutDays;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime.utc(month.year, month.month, 1);
    final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
    final leading = first.weekday - DateTime.monday;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      key: const Key('month-calendar'),
      children: [
        Row(
          children: [
            for (final label in _labels)
              Expanded(
                child: AppText(
                  label,
                  style: subtitleTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _cell(
                    context,
                    index: row * 7 + col,
                    leading: leading,
                    daysInMonth: daysInMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context, {
    required int index,
    required int leading,
    required int daysInMonth,
  }) {
    final dayNumber = index - leading + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 48);
    }
    final day = DateTime.utc(month.year, month.month, dayNumber);
    final isToday = today.year == day.year &&
        today.month == day.month &&
        today.day == day.day;
    final hasWorkout = workoutDays.contains(dayNumber);
    final theme = Theme.of(context);

    return InkWell(
      key: Key('month-day-$dayNumber'),
      onTap: () => onDayTap(day),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: AppText('$dayNumber', style: dataTextStyle),
            ),
            SizedBox(
              height: 6,
              child: hasWorkout
                  ? Container(
                      key: Key('month-dot-$dayNumber'),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTrendTile extends StatelessWidget {
  const _ExerciseTrendTile({required this.row});

  final ExerciseMonthTrend row;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: Key('exercise-trend-${row.titleKey}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: AppText(row.title, style: dataTextStyle),
      subtitle: AppText(
        row.feltEasier
            ? '${formatTrendSummary(row)}  ·  felt easier'
            : formatTrendSummary(row),
        style: subtitleTextStyle,
      ),
      children: [
        for (final point in row.sessions)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: AppText(
              point.primaryValue == null
                  ? 'No logged sets'
                  : formatMetricValue(row.metric, point.primaryValue!),
              style: dataTextStyle,
            ),
            subtitle: AppText(
              '${point.completedSets}/${point.prescribedSets} sets'
              '${point.difficulty == null ? '' : '  ·  ★${point.difficulty}'}',
              style: subtitleTextStyle,
            ),
          ),
      ],
    );
  }
}
