import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../data/app_ports.dart';
import '../../domain/models/models.dart';
import '../../domain/plan_repository.dart';
import '../workout/start_workout.dart';
import 'day_editor_page.dart';
import 'exercise_block_row.dart';
import '../../domain/today_suggestion.dart';

class DayPreviewArgs {
  const DayPreviewArgs({required this.planId, required this.dayId});

  /// [WorkoutPlan.uuid], not a local row key.
  final String planId;
  final String dayId;
}

/// Read-only day: block list from Isar, then start (live workout is next).
class DayPreviewPage extends StatefulWidget {
  const DayPreviewPage({
    super.key,
    required this.planId,
    required this.dayId,
    required this.ports,
  });

  /// [WorkoutPlan.uuid], not a local row key.
  final String planId;
  final String dayId;
  final AppPorts ports;

  @override
  State<DayPreviewPage> createState() => _DayPreviewPageState();
}

class _DayPreviewPageState extends State<DayPreviewPage> {
  PlanRepository get _plans => widget.ports.plans;
  WorkoutPlan? _plan;
  PlanDay? _day;
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
      final plan = await _plans.byUuid(widget.planId);
      PlanDay? day;
      if (plan != null) {
        for (final item in plan.days) {
          if (item.dayId == widget.dayId) {
            day = item;
            break;
          }
        }
      }
      if (!mounted || id != _loadId) return;
      setState(() {
        _plan = plan;
        _day = day;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_day == null) {
          _error = 'Could not load this day.';
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

  Future<void> _edit() async {
    // Push the editor widget directly. GetX nested-route rules make
    // `Get.toNamed` from some plan screens a no-op.
    await Get.to(
      () => DayEditorPage(
        planId: widget.planId,
        dayId: widget.dayId,
        ports: widget.ports,
      ),
      routeName: AppRoutes.editDay,
    );
    await _load();
  }

  Future<void> _startWorkout() async {
    final plan = _plan;
    final day = _day;
    if (plan == null || day == null) return;
    await startWorkout(
      context: context,
      plan: plan,
      day: day,
      start: widget.ports.startSession,
      ports: widget.ports,
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    return Scaffold(
      appBar: AppBar(
        title: AppText(day?.title ?? 'Day', style: titleTextStyle),
      ),
      body: _error != null && day == null
          ? AppLoadError(message: _error!, onRetry: _retry)
          : _loading && day == null
              ? const Center(child: CircularProgressIndicator())
              : day == null
                  ? const Center(child: AppText('This day is no longer here.'))
                  : _body(context, day),
    );
  }

  bool _canStart(PlanDay day) {
    final plan = _plan;
    if (plan == null) return false;
    return dayCanStart(plan, day);
  }

  Widget _body(BuildContext context, PlanDay day) {
    final theme = Theme.of(context);
    final plan = _plan;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('edit-day'),
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit day'),
            ),
          ),
          if (day.summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(day.summary, style: subtitleTextStyle),
              ),
            ),
          if (plan != null && plan.commonSections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  'Common sections can be included when you start.',
                  style: subtitleTextStyle,
                ),
              ),
            ),
          Expanded(
            child: day.blocks.isEmpty
                ? const Center(
                    child: AppText(
                      'No exercises on this day yet.',
                      style: subtitleTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: day.blocks.length,
                    itemBuilder: (context, index) {
                      return ExerciseBlockRow(
                        key: Key('block-row-${day.blocks[index].blockId}'),
                        block: day.blocks[index],
                        backgroundColor: index % 2 == 0
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.cardColor,
                        borderColor: theme.colorScheme.primaryContainer,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: AppElevatedButton(
                data: 'Start workout',
                onPressed: _canStart(day) ? _startWorkout : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
