import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/app_ports.dart';
import '../../domain/models/models.dart';
import '../../domain/new_id.dart';
import '../../domain/plan_catalog.dart';
import '../../domain/plan_repository.dart';
import 'day_card_summary.dart';
import 'day_editor_page.dart';
import 'day_preview_page.dart';
import 'rotating_exercise_thumbnail.dart';

/// One plan: rename it, add days, open a day to edit its workout.
class PlanPage extends StatefulWidget {
  const PlanPage({super.key, required this.planId, required this.ports});

  /// [WorkoutPlan.uuid], not a local row key.
  final String planId;
  final AppPorts ports;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  PlanRepository get _plans => widget.ports.plans;
  WorkoutPlan? _plan;
  bool _loading = true;
  String? _error;
  int _loadId = 0;
  StreamSubscription<void>? _watch;

  @override
  void initState() {
    super.initState();
    _load();
    _watch = _plans.watch().listen((_) => _load());
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final plan = await _plans.byUuid(widget.planId);
      if (!mounted || id != _loadId) return;
      setState(() {
        _plan = plan;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_plan == null) {
          _error = 'Could not load this plan.';
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

  Future<void> _save(WorkoutPlan plan) async {
    await _plans.save(plan);
    await _load();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _rename() async {
    final plan = _plan;
    if (plan == null) return;
    final controller = TextEditingController(text: plan.title);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename plan'),
        content: AppTextField(
          label: 'title',
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty) return;

    plan.title = next;
    await _save(plan);
  }

  Future<void> _addDay() async {
    final plan = _plan;
    if (plan == null) return;
    final created = await showDialog<_AddDayResult>(
      context: context,
      builder: (context) => _AddDayDialog(
        defaultTitle: 'Day ${plan.days.length + 1}',
      ),
    );
    if (created == null || !mounted) return;
    final title =
        created.title.isEmpty ? 'Day ${plan.days.length + 1}' : created.title;
    final day = PlanDay.create(
      dayId: newId(),
      title: title,
      summary: created.summary,
    );
    plan.days = [...plan.days, day];
    await _save(plan);
    if (!mounted) return;
    await _openEditor(day);
  }

  Future<void> _deleteDay(PlanDay day) async {
    final plan = _plan;
    if (plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this day?'),
        content: Text('"${day.title}" and its exercises will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    plan.days = [
      for (final item in plan.days)
        if (item.dayId != day.dayId) item,
    ];
    await _save(plan);
  }

  Future<void> _deletePlan() async {
    final plan = _plan;
    if (plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: const Text('Workouts already logged stay on Month.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-plan'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _plans.delete(plan.id);
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _openDay(PlanDay day) async {
    await Get.to(
      () => DayPreviewPage(
        planId: widget.planId,
        dayId: day.dayId,
        ports: widget.ports,
      ),
      routeName: AppRoutes.day,
    );
    await _load();
  }

  Future<void> _openEditor(PlanDay day) async {
    await Get.to(
      () => DayEditorPage(
        planId: widget.planId,
        dayId: day.dayId,
        ports: widget.ports,
      ),
      routeName: AppRoutes.editDay,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(
          plan?.displayTitle ?? 'Plan',
          style: titleTextStyle,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Rename plan',
            onPressed: plan == null ? null : _rename,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const Key('add-day'),
            tooltip: 'Add day',
            onPressed: plan == null ? null : _addDay,
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            enabled: plan != null,
            onSelected: (value) {
              if (value == 'delete') _deletePlan();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                key: Key('delete-plan'),
                value: 'delete',
                child: Text('Delete plan'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: plan == null || plan.days.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addDay,
              icon: const Icon(Icons.add),
              label: const Text('Add day'),
            ),
      body: _error != null && plan == null
          ? AppLoadError(message: _error!, onRetry: _retry)
          : _loading && plan == null
              ? const Center(child: CircularProgressIndicator())
              : plan == null
                  ? const Center(child: AppText('This plan is no longer here.'))
                  : _daysBody(context, plan),
    );
  }

  Widget _daysBody(BuildContext context, WorkoutPlan plan) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      children: [
        if (plan.days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const AppText(
                  'No days yet. Add a day, then fill it with exercises.',
                  style: subtitleTextStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add day'),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < plan.days.length; index++)
            _DayCard(
              key: Key('day-card-${plan.days[index].dayId}'),
              day: plan.days[index],
              onOpen: () => _openDay(plan.days[index]),
              onDelete: () => _deleteDay(plan.days[index]),
            ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    super.key,
    required this.day,
    required this.onOpen,
    required this.onDelete,
  });

  final PlanDay day;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focus = dayFocusLabel(day);
    final estimate = dayEstimateLabel(day);
    final volume = dayVolumeLabel(day);
    final chips = dayCardVisibleTargetAreaIds(day);
    final extra = dayCardHiddenTargetAreaCount(day);
    final thumbnails = dayCardThumbnails(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(day.title, style: titleTextStyle),
                          ),
                          IconButton(
                            tooltip: 'Delete day',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      if (focus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            focus,
                            key: const Key('day-card-focus'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (chips.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final id in chips)
                                Chip(
                                  key: Key('day-card-chip-$id'),
                                  label: Text(targetAreaLabel(id)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  side: BorderSide.none,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              if (extra > 0)
                                Chip(
                                  key: const Key('day-card-more-targets'),
                                  label: Text('+$extra'),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  side: BorderSide.none,
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (estimate.isNotEmpty) ...[
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              estimate,
                              key: const Key('day-card-estimate'),
                              style: subtitleTextStyle,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              volume,
                              key: const Key('day-card-volume'),
                              style: subtitleTextStyle,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (thumbnails.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: RotatingExerciseThumbnail(
                      key: Key('day-card-thumbnails-${day.dayId}'),
                      media: thumbnails,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddDayResult {
  const _AddDayResult({required this.title, required this.summary});

  final String title;
  final String summary;
}

class _AddDayDialog extends StatefulWidget {
  const _AddDayDialog({required this.defaultTitle});

  final String defaultTitle;

  @override
  State<_AddDayDialog> createState() => _AddDayDialogState();
}

class _AddDayDialogState extends State<_AddDayDialog> {
  late final TextEditingController _title;
  late final TextEditingController _summary;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.defaultTitle);
    _summary = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add day'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'day title',
            controller: _title,
            autofocus: true,
          ),
          AppTextField(
            label: 'day summary',
            hint: 'muscles, focus, notes…',
            maxLines: 2,
            controller: _summary,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _AddDayResult(
              title: _title.text.trim(),
              summary: _summary.text.trim(),
            ),
          ),
          child: const Text('Save day'),
        ),
      ],
    );
  }
}
