import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/models/models.dart';
import '../../data/session_repository.dart';
import 'progress_format.dart';

/// Several sessions on one calendar day, oldest [WorkoutSession.startedAt] first.
class DayLogPage extends StatefulWidget {
  const DayLogPage({super.key, required this.day});

  final DateTime day;

  @override
  State<DayLogPage> createState() => _DayLogPageState();
}

class _DayLogPageState extends State<DayLogPage> {
  final SessionRepository _sessions = Get.find<SessionRepository>();
  List<WorkoutSession> _items = const [];
  bool _loading = true;
  String? _error;
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final items = await _sessions.forCalendarDay(widget.day);
      if (!mounted || id != _loadId) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) {
          _error = 'Could not load this day.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appbar: AppBar(
        title: AppText(_dayTitle(widget.day), style: titleTextStyle),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppLoadError(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return const Center(
        child: AppText(
          'No workouts this day.',
          style: subtitleTextStyle,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      key: const Key('day-log-list'),
      children: [
        for (final session in _items)
          ListTile(
            key: Key('day-log-session-${session.id}'),
            contentPadding: EdgeInsets.zero,
            title: AppText(session.dayTitleSnapshot, style: dataTextStyle),
            subtitle: AppText(
              '${session.planTitleSnapshot}  ·  ${_statusLabel(session.status)}',
              style: subtitleTextStyle,
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => Get.toNamed(
              AppRoutes.sessionLog,
              arguments: session.id,
            ),
          ),
      ],
    );
  }
}

/// Read-only log of one session from the month calendar.
class SessionLogPage extends StatefulWidget {
  const SessionLogPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SessionLogPage> createState() => _SessionLogPageState();
}

class _SessionLogPageState extends State<SessionLogPage> {
  final SessionRepository _sessions = Get.find<SessionRepository>();
  WorkoutSession? _session;
  bool _loading = true;
  String? _error;
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final session = await _sessions.byId(widget.sessionId);
      if (!mounted || id != _loadId) return;
      setState(() {
        _session = session;
        _loading = false;
        _error = session == null ? 'This session is gone.' : null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_session == null) {
          _error = 'Could not load this session.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appbar: AppBar(
        title: AppText(
          _session?.dayTitleSnapshot ?? 'Session',
          style: titleTextStyle,
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppLoadError(message: _error!, onRetry: _load);
    }
    final session = _session!;
    return ListView(
      key: Key('session-log-${session.id}'),
      children: [
        AppText(session.planTitleSnapshot, style: dataTextStyle),
        const SizedBox(height: 4),
        AppText(
          _statusLabel(session.status),
          style: subtitleTextStyle,
        ),
        const SizedBox(height: 16),
        for (final log in session.exerciseLogs) ...[
          _ExerciseLogCard(log: log),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ExerciseLogCard extends StatelessWidget {
  const _ExerciseLogCard({required this.log});

  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(log.exerciseTitle, style: dataTextStyle),
              ),
              if (log.difficulty != null)
                AppText('★${log.difficulty}', style: dataTextStyle),
            ],
          ),
          const SizedBox(height: 8),
          if (log.sets.isEmpty)
            const AppText('No sets logged', style: subtitleTextStyle)
          else
            for (final set in log.sets)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AppText(formatSetLine(set), style: subtitleTextStyle),
              ),
        ],
      ),
    );
  }
}

String _statusLabel(SessionStatus status) {
  switch (status) {
    case SessionStatus.inProgress:
      return 'In progress';
    case SessionStatus.completed:
      return 'Completed';
    case SessionStatus.abandoned:
      return 'Discarded';
  }
}

String _dayTitle(DateTime day) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${day.day} ${months[day.month - 1]} ${day.year}';
}
