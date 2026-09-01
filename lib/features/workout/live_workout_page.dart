import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../data/session_repository.dart';
import 'workout_controller.dart';

/// Live logger: one active exercise, log what you did, rest, then rate 1–5.
class LiveWorkoutPage extends StatefulWidget {
  const LiveWorkoutPage({super.key, required this.sessionId});

  /// [WorkoutSession.uuid], not a local row key.
  final String sessionId;

  @override
  State<LiveWorkoutPage> createState() => _LiveWorkoutPageState();
}

class _LiveWorkoutPageState extends State<LiveWorkoutPage> {
  late final WorkoutController _controller;
  final _reps = TextEditingController();
  final _weight = TextEditingController();
  String? _syncedPrescriptionId;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WorkoutController(
      sessionId: widget.sessionId,
      sessions: Get.find<SessionRepository>(),
    );
    Get.put(_controller);
    _load();
  }

  Future<void> _load() async {
    try {
      await _controller.load();
      if (!mounted) return;
      _syncFields(_controller.activeLog);
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open this workout.';
      });
    }
  }

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    if (Get.isRegistered<WorkoutController>() &&
        Get.find<WorkoutController>() == _controller) {
      Get.delete<WorkoutController>();
    } else {
      _controller.onClose();
    }
    super.dispose();
  }

  void _syncFields(ExerciseLog? log) {
    if (log == null) {
      _syncedPrescriptionId = null;
      return;
    }
    if (_syncedPrescriptionId == log.prescriptionId) return;
    _syncedPrescriptionId = log.prescriptionId;
    _reps.text = log.prescribedReps?.toString() ?? '';
    final lastWeight = log.sets.isEmpty ? null : log.sets.last.weightKg;
    _weight.text = lastWeight == null
        ? ''
        : (lastWeight == lastWeight.roundToDouble()
            ? lastWeight.round().toString()
            : lastWeight.toString());
  }

  Future<void> _logSet() async {
    final typed = int.tryParse(_reps.text.trim());
    final reps = typed ?? _controller.activeLog?.prescribedReps;
    final weightRaw = _weight.text.trim();
    final weight = weightRaw.isEmpty ? null : double.tryParse(weightRaw);
    if (weightRaw.isNotEmpty && weight == null) {
      _toast('Weight must be a number, or leave it empty.');
      return;
    }
    try {
      await _controller.logSet(reps: reps, weightKg: weight);
    } on WorkoutActionException catch (error) {
      _toast(error.message);
    }
  }

  Future<void> _logTime() async {
    try {
      await _controller.logTime();
    } on WorkoutActionException catch (error) {
      _toast(error.message);
    }
  }

  Future<void> _rate(int difficulty) async {
    try {
      await _controller.rate(difficulty);
    } on WorkoutActionException catch (error) {
      _toast(error.message);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _end() async {
    final action = await showModalBottomSheet<_EndAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('finish-workout'),
                title: const Text('Finish workout'),
                subtitle: const Text('Keep what you logged, even if it is partial.'),
                onTap: () => Navigator.pop(context, _EndAction.finish),
              ),
              ListTile(
                key: const Key('discard-workout'),
                title: const Text('Discard workout'),
                subtitle: const Text('This session will not count on the month view.'),
                onTap: () => Navigator.pop(context, _EndAction.discard),
              ),
              ListTile(
                title: const Text('Keep going'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == _EndAction.finish) {
      await _controller.finish();
    } else if (action == _EndAction.discard) {
      await _controller.discard();
      if (!mounted) return;
      _leave();
    }
  }

  void _leave() {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WorkoutController>(
      builder: (controller) {
        final session = controller.session;
        final activeId = controller.activeLog?.prescriptionId;
        if (activeId != _syncedPrescriptionId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _syncFields(controller.activeLog);
          });
        }
        return AppScaffold(
          appbar: AppBar(
            title: AppText(
              session?.dayTitleSnapshot ?? 'Workout',
              style: titleTextStyle,
            ),
            actions: [
              if (controller.isLive)
                TextButton(
                  key: const Key('end-workout'),
                  onPressed: _end,
                  child: const Text('End'),
                ),
            ],
          ),
          body: _error != null && session == null
              ? AppLoadError(message: _error!, onRetry: _load)
              : _loading && session == null
                  ? const Center(child: CircularProgressIndicator())
                  : session == null
                      ? const Center(
                          child: AppText('This workout is no longer here.'),
                        )
                      : _body(context, controller, session),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    WorkoutController controller,
    WorkoutSession session,
  ) {
    if (!controller.isLive) {
      final discarded = session.status == SessionStatus.abandoned;
      return _EndedView(
        discarded: discarded,
        onDone: _leave,
      );
    }
    if (session.exerciseLogs.isEmpty) {
      return const Center(
        child: AppText(
          'Nothing to log. End this workout or go back.',
          style: subtitleTextStyle,
          textAlign: TextAlign.center,
        ),
      );
    }

    final active = controller.activeLog;
    return ListView(
      children: [
        if (active != null) _header(controller, active),
        const SizedBox(height: 12),
        const AppText('This block', style: dataTextStyle),
        const SizedBox(height: 8),
        for (final log in controller.currentBlockLogs)
          _BlockLogTile(
            log: log,
            active: identical(log, active) ||
                log.prescriptionId == active?.prescriptionId,
          ),
        const SizedBox(height: 16),
        if (active != null) _logger(controller, active),
        const SizedBox(height: 16),
        _rest(controller),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _header(WorkoutController controller, ExerciseLog active) {
    final extras = controller.inExtrasPhase;
    final setLabel = extras
        ? 'set ${controller.headerSetIndex}  ·  extra'
        : 'set ${controller.headerSetIndex} of ${active.prescribedSets}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          '${active.exerciseTitle}  ·  $setLabel',
          style: titleTextStyle,
        ),
        const SizedBox(height: 4),
        const AppText(
          'Log what you did on this set.',
          style: subtitleTextStyle,
        ),
      ],
    );
  }

  Widget _logger(WorkoutController controller, ExerciseLog active) {
    if (active.difficulty != null) {
      return const AppText('This exercise is rated. Next up is below.');
    }
    final showRate = controller.canRate(active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.prescribedDurationSeconds != null)
          _durationLogger(controller, active)
        else
          _repLogger(controller, active),
        if (showRate) ...[
          const SizedBox(height: 16),
          const AppText(
            'How hard was that? 1 easy · 5 hard',
            style: dataTextStyle,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var n = 1; n <= 5; n++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: n == 5 ? 0 : 6),
                    child: OutlinedButton(
                      key: Key('rate-$n'),
                      onPressed: () => _rate(n),
                      child: Text('$n'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _repLogger(WorkoutController controller, ExerciseLog active) {
    final canLog = controller.canLogSet(active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                key: const Key('weight-field'),
                label: 'Weight (kg)',
                hint: 'empty = bodyweight',
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                key: const Key('reps-field'),
                label: 'Reps',
                controller: _reps,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        AppElevatedButton(
          data: 'Log set',
          onPressed: canLog ? _logSet : null,
        ),
      ],
    );
  }

  Widget _durationLogger(WorkoutController controller, ExerciseLog active) {
    final remaining =
        controller.durationRemainingSeconds ?? active.prescribedDurationSeconds!;
    final canLog = controller.canLogTime(active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          formatSignedClock(remaining),
          style: titleTextStyle.copyWith(fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const AppText(
          'Start the hold, then log the time you actually did.',
          style: subtitleTextStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AppElevatedButton(
          data: controller.isDurationRunning ? 'Running…' : 'Start timer',
          onPressed: controller.isDurationRunning || !canLog
              ? null
              : controller.startDurationCountdown,
        ),
        const SizedBox(height: 8),
        AppElevatedButton(
          outlined: true,
          data: 'Log time',
          onPressed: canLog ? _logTime : null,
        ),
      ],
    );
  }

  Widget _rest(WorkoutController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Rest  ${formatSignedClock(controller.restElapsedSeconds)}',
          style: dataTextStyle,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppElevatedButton(
                data: controller.isResting ? 'Resting…' : 'Start rest',
                onPressed: controller.isResting ? null : controller.startRest,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppElevatedButton(
                outlined: true,
                data: 'Reset rest',
                onPressed: controller.resetRest,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _EndAction { finish, discard }

class _BlockLogTile extends StatelessWidget {
  const _BlockLogTile({required this.log, required this.active});

  final ExerciseLog log;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final load = log.prescribedDurationSeconds != null
        ? '${log.prescribedSets} × ${log.prescribedDurationSeconds}s'
        : '${log.prescribedSets} × ${log.prescribedReps ?? 0}';
    final done = '${log.sets.length}/${log.prescribedSets}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                log.exerciseTitle,
                style: dataTextStyle.copyWith(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AppText('$load  ·  $done', style: subtitleTextStyle),
            if (log.difficulty != null) ...[
              const SizedBox(width: 8),
              AppText('★${log.difficulty}', style: dataTextStyle),
            ],
          ],
        ),
      ),
    );
  }
}

class _EndedView extends StatelessWidget {
  const _EndedView({required this.discarded, required this.onDone});

  final bool discarded;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            discarded ? 'Workout discarded' : 'Workout complete',
            style: titleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText(
            discarded
                ? 'This session will not show on the month view.'
                : 'Nice work. What you logged is saved.',
            style: subtitleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppElevatedButton(data: 'Done', onPressed: onDone),
        ],
      ),
    );
  }
}

/// `m:ss`. Negative remaining (overtime) is shown with a leading `+`.
String formatSignedClock(int seconds) {
  final overtime = seconds < 0;
  final abs = seconds.abs();
  final body = '${abs ~/ 60}:${(abs % 60).toString().padLeft(2, '0')}';
  return overtime ? '+$body' : body;
}
