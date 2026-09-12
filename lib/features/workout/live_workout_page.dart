import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/exercise_asset_catalog.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/app_ports.dart';
import '../../domain/models/models.dart';
import '../plans/exercise_media.dart';
import '../plans/exercise_media_thumbnail.dart';
import 'live_session_progress.dart';
import 'live_workout_copy.dart';
import 'workout_controller.dart';

/// Live logger: work mode, calm rest takeover, soft rate, companion copy.
class LiveWorkoutPage extends StatefulWidget {
  const LiveWorkoutPage({
    super.key,
    required this.sessionId,
    required this.ports,
  });

  /// [WorkoutSession.uuid], not a local row key.
  final String sessionId;
  final AppPorts ports;

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

  static const _weightStep = 2.5;

  @override
  void initState() {
    super.initState();
    _controller = WorkoutController(
      sessionId: widget.sessionId,
      sessions: widget.ports.sessions,
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

  Future<void> _skipRate() async {
    try {
      await _controller.skipRating();
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

  void _nudgeReps(int delta) {
    final current = int.tryParse(_reps.text.trim()) ??
        _controller.activeLog?.prescribedReps ??
        1;
    final next = current + delta;
    _reps.text = (next < 1 ? 1 : next).toString();
    setState(() {});
  }

  void _nudgeWeight(double delta) {
    final raw = _weight.text.trim();
    final current = raw.isEmpty ? null : double.tryParse(raw);
    if (current == null) {
      if (delta > 0) {
        _weight.text = _formatWeight(_weightStep);
      }
      setState(() {});
      return;
    }
    final next = current + delta;
    if (next <= 0) {
      _weight.text = '';
    } else {
      _weight.text = _formatWeight(next);
    }
    setState(() {});
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
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
                subtitle: const Text(
                  'Keep what you logged, even if it is partial.',
                ),
                onTap: () => Navigator.pop(context, _EndAction.finish),
              ),
              ListTile(
                key: const Key('discard-workout'),
                title: Text(
                  'Discard workout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'This session will not count on the month view.',
                ),
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
              if (controller.isLive && !controller.sessionDoneBeat)
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
    if (controller.sessionDoneBeat) {
      return _SessionDoneBeat(
        message: LiveWorkoutCopy.sessionDoneBeat(
          controller.sessionDoneDifficulty,
        ),
        onContinue: () async {
          await controller.acknowledgeSessionDone();
        },
      );
    }
    if (!controller.isLive) {
      final discarded = session.status == SessionStatus.abandoned;
      return _EndedView(
        discarded: discarded,
        summary: discarded ? null : sessionSavedSummary(session),
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

    if (controller.isResting) {
      return _restMode(controller, session);
    }

    final active = controller.activeLog;
    final progress = liveSessionProgress(session);
    return ListView(
      children: [
        const AppText(
          LiveWorkoutCopy.leaveReassurance,
          style: subtitleTextStyle,
        ),
        const SizedBox(height: 12),
        if (progress.line.isNotEmpty) ...[
          AppText(progress.line, style: subtitleTextStyle),
          const SizedBox(height: 12),
        ],
        if (active != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActiveMedia(title: active.exerciseTitle),
              const SizedBox(width: 12),
              Expanded(child: _header(controller, active)),
            ],
          ),
        ],
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _restMode(WorkoutController controller, WorkoutSession session) {
    final progress = liveSessionProgress(session);
    final active = controller.activeLog;
    final subtitle = _restSubtitle(controller, active);
    return ListView(
      children: [
        const AppText(
          LiveWorkoutCopy.leaveReassurance,
          style: subtitleTextStyle,
        ),
        const SizedBox(height: 12),
        if (progress.line.isNotEmpty) ...[
          AppText(progress.line, style: subtitleTextStyle),
          const SizedBox(height: 24),
        ],
        AppText(
          formatSignedClock(controller.restElapsedSeconds),
          key: const Key('rest-clock'),
          style: titleTextStyle.copyWith(fontSize: 56, height: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const AppText(
          LiveWorkoutCopy.restBreathe,
          style: subtitleTextStyle,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          AppText(
            subtitle,
            style: dataTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        AppElevatedButton(
          key: const Key('end-rest'),
          data: LiveWorkoutCopy.imReady,
          onPressed: controller.endRest,
        ),
      ],
    );
  }

  String? _restSubtitle(WorkoutController controller, ExerciseLog? active) {
    if (active == null) return null;
    if (!controller.isPrescribedPhase && controller.canRate(active)) {
      return LiveWorkoutCopy.rateWhenReady(active.exerciseTitle);
    }
    return LiveWorkoutCopy.nextUp(active.exerciseTitle);
  }

  Widget _header(WorkoutController controller, ExerciseLog active) {
    final extras = controller.inExtrasPhase;
    final setLabel = extras
        ? 'set ${controller.headerSetIndex}  ·  extra'
        : 'set ${controller.headerSetIndex} of ${active.prescribedSets}';
    final partner = controller.companionCueLog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          LiveWorkoutCopy.yourTurn(active.exerciseTitle),
          style: titleTextStyle,
        ),
        if (partner != null) ...[
          const SizedBox(height: 2),
          AppText(
            LiveWorkoutCopy.thenPartner(partner.exerciseTitle),
            style: subtitleTextStyle,
          ),
        ],
        const SizedBox(height: 4),
        AppText(setLabel, style: dataTextStyle),
      ],
    );
  }

  Widget _logger(WorkoutController controller, ExerciseLog active) {
    if (active.isComplete) {
      return const AppText(LiveWorkoutCopy.ratedNext);
    }
    final showRate = controller.canRate(active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showRate) ...[
          const AppText(LiveWorkoutCopy.ratePrompt, style: dataTextStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var n = 1; n <= 5; n++)
                OutlinedButton(
                  key: Key('rate-$n'),
                  onPressed: () => _rate(n),
                  child: Text(LiveWorkoutCopy.rateLabels[n]!),
                ),
            ],
          ),
          TextButton(
            key: const Key('skip-rating'),
            onPressed: _skipRate,
            child: const Text(LiveWorkoutCopy.skipRating),
          ),
          const SizedBox(height: 16),
        ],
        if (active.prescribedDurationSeconds != null)
          _durationLogger(controller, active)
        else
          _repLogger(controller, active),
      ],
    );
  }

  Widget _repLogger(WorkoutController controller, ExerciseLog active) {
    final canLog = controller.canLogSet(active);
    final weightEmpty = _weight.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText(LiveWorkoutCopy.saveSetPrompt, style: subtitleTextStyle),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StepperField(
                label: 'Weight (kg)',
                fieldKey: const Key('weight-field'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                onMinus: () => _nudgeWeight(-_weightStep),
                onPlus: () => _nudgeWeight(_weightStep),
                minusKey: const Key('weight-minus'),
                plusKey: const Key('weight-plus'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StepperField(
                label: 'Reps',
                fieldKey: const Key('reps-field'),
                controller: _reps,
                keyboardType: TextInputType.number,
                onMinus: () => _nudgeReps(-1),
                onPlus: () => _nudgeReps(1),
                minusKey: const Key('reps-minus'),
                plusKey: const Key('reps-plus'),
              ),
            ),
          ],
        ),
        if (weightEmpty) ...[
          const SizedBox(height: 4),
          const AppText(
            LiveWorkoutCopy.bodyweightHint,
            style: subtitleTextStyle,
          ),
        ],
        AppElevatedButton(
          key: const Key('save-set'),
          data: LiveWorkoutCopy.saveSet,
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
          'Start the hold, then save the time you actually did.',
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
}

enum _EndAction { finish, discard }

class _ActiveMedia extends StatelessWidget {
  const _ActiveMedia({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final asset = matchExerciseAsset(title);
    if (asset == null) return const SizedBox.shrink();
    final gif = asset.gifPath;
    final media = ExerciseMediaRef(
      uri: gif,
      source: ExerciseMediaSource.asset,
      kind: ExerciseMediaKind.gif,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: ExerciseMediaThumbnail.media(
        media: media,
        size: 88,
        borderRadius: 12,
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.keyboardType,
    required this.onMinus,
    required this.onPlus,
    required this.minusKey,
    required this.plusKey,
    this.onChanged,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final Key minusKey;
  final Key plusKey;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: fieldKey,
          label: label,
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: minusKey,
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
              tooltip: 'Decrease',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              key: plusKey,
              onPressed: onPlus,
              icon: const Icon(Icons.add),
              tooltip: 'Increase',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

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
            ] else if (log.isComplete) ...[
              const SizedBox(width: 8),
              AppText('done', style: subtitleTextStyle),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionDoneBeat extends StatelessWidget {
  const _SessionDoneBeat({
    required this.message,
    required this.onContinue,
  });

  final String message;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              message,
              key: const Key('session-done-beat'),
              style: titleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppElevatedButton(
              key: const Key('session-done-continue'),
              data: 'Continue',
              onPressed: () => onContinue(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndedView extends StatelessWidget {
  const _EndedView({
    required this.discarded,
    required this.onDone,
    this.summary,
  });

  final bool discarded;
  final VoidCallback onDone;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            discarded
                ? LiveWorkoutCopy.discarded
                : LiveWorkoutCopy.workoutComplete,
            style: titleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText(
            discarded
                ? LiveWorkoutCopy.discardedDetail
                : LiveWorkoutCopy.niceWork,
            style: subtitleTextStyle,
            textAlign: TextAlign.center,
          ),
          if (!discarded && summary != null) ...[
            const SizedBox(height: 4),
            AppText(
              summary!,
              style: dataTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
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
