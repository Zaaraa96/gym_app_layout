import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/app_ports.dart';
import '../../domain/models/models.dart';
import '../../domain/plan_catalog.dart';
import '../../domain/plan_validation.dart';
import 'block_summary.dart';
import 'exercise_asset_catalog.dart' as catalog;
import 'exercise_block_dialog.dart';
import 'exercise_media_thumbnail.dart';
import 'plan_builder_controller.dart';
import 'target_area_chips.dart';

/// One-screen vertical stepper for creating a plan as a draft.
class PlanBuilderPage extends StatefulWidget {
  const PlanBuilderPage({
    super.key,
    required this.ports,
    this.planId,
  });

  final AppPorts ports;
  final String? planId;

  @override
  State<PlanBuilderPage> createState() => _PlanBuilderPageState();
}

class _PlanBuilderPageState extends State<PlanBuilderPage>
    with WidgetsBindingObserver {
  PlanBuilderController? _controller;
  Object? _loadError;
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _dayTitles = <String, TextEditingController>{};
  final _daySummaries = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_syncFields);
      unawaitedFlush(controller);
    }
    _title.dispose();
    _description.dispose();
    for (final item in _dayTitles.values) {
      item.dispose();
    }
    for (final item in _daySummaries.values) {
      item.dispose();
    }
    super.dispose();
  }

  void unawaitedFlush(PlanBuilderController controller) {
    if (controller.plan.status != PlanStatus.active) {
      controller.flush();
    }
    controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.flush();
    }
  }

  Future<void> _open() async {
    try {
      final controller = widget.planId == null
          ? await PlanBuilderController.openNew(widget.ports.plans)
          : await PlanBuilderController.openExisting(
              widget.ports.plans,
              widget.planId!,
            );
      if (!mounted) {
        controller.dispose();
        return;
      }
      _bind(controller);
      setState(() {
        _controller = controller;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _bind(PlanBuilderController controller) {
    _title.text = controller.plan.title;
    _description.text = controller.plan.description;
    _syncDayControllers(controller.plan);
    controller.addListener(_syncFields);
  }

  void _syncFields() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (_title.text != controller.plan.title) {
      _title.value = _title.value.copyWith(text: controller.plan.title);
    }
    if (_description.text != controller.plan.description) {
      _description.value = _description.value.copyWith(
        text: controller.plan.description,
      );
    }
    _syncDayControllers(controller.plan);
    setState(() {});
  }

  void _syncDayControllers(WorkoutPlan plan) {
    final ids = {for (final day in plan.days) day.dayId};
    for (final id in _dayTitles.keys.toList()) {
      if (!ids.contains(id)) {
        _dayTitles.remove(id)?.dispose();
        _daySummaries.remove(id)?.dispose();
      }
    }
    for (final day in plan.days) {
      _dayTitles.putIfAbsent(
        day.dayId,
        () => TextEditingController(text: day.title),
      );
      _daySummaries.putIfAbsent(
        day.dayId,
        () => TextEditingController(text: day.summary),
      );
      if (_dayTitles[day.dayId]!.text != day.title) {
        _dayTitles[day.dayId]!.text = day.title;
      }
      if (_daySummaries[day.dayId]!.text != day.summary) {
        _daySummaries[day.dayId]!.text = day.summary;
      }
    }
  }

  Future<void> _leave() async {
    await _controller?.flush();
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _create() async {
    final controller = _controller;
    if (controller == null) return;
    final ok = await controller.activate();
    if (!mounted) return;
    if (!ok) return;
    await Get.offAllNamed(AppRoutes.plan, arguments: controller.plan.uuid);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: AppScaffold(
        appbar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _leave,
          ),
          title: AppText('Create plan', style: titleTextStyle),
          actions: [
            if (controller != null) _SaveStatus(controller: controller),
          ],
        ),
        body: _loadError != null
            ? Center(child: AppText('Could not open the builder. $_loadError'))
            : controller == null
                ? const Center(child: CircularProgressIndicator())
                : _BuilderBody(
                    controller: controller,
                    title: _title,
                    description: _description,
                    dayTitles: _dayTitles,
                    daySummaries: _daySummaries,
                    onCreate: _create,
                    onLeave: _leave,
                    onAddBlock: _addOrEditBlock,
                  ),
      ),
    );
  }

  Future<void> _addOrEditBlock(
    PlanBuilderController controller,
    PlanDay day, {
    ExerciseBlock? existing,
    int? index,
  }) async {
    final result = await showExerciseBlockDialog(
      context,
      existing: existing,
      goalIds: controller.plan.goalIds,
    );
    if (result == null) return;
    final blocks = List<ExerciseBlock>.from(day.blocks);
    if (index == null) {
      blocks.add(result);
    } else {
      blocks[index] = result;
    }
    controller.setDayBlocks(day.dayId, blocks);
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.controller});

  final PlanBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final String label;
    late final IconData icon;
    late final Color color;
    switch (controller.saveStatus) {
      case DraftSaveStatus.saving:
        label = 'Saving…';
        icon = Icons.cloud_upload_outlined;
        color = theme.colorScheme.primary;
      case DraftSaveStatus.saved:
        label = 'Draft saved';
        icon = Icons.cloud_done_outlined;
        color = theme.colorScheme.primary;
      case DraftSaveStatus.failed:
        label = 'Could not save';
        icon = Icons.cloud_off_outlined;
        color = theme.colorScheme.error;
    }
    return Semantics(
      liveRegion: true,
      label: label,
      child: TextButton.icon(
        key: const Key('save-status'),
        onPressed: controller.saveStatus == DraftSaveStatus.failed
            ? controller.retrySave
            : null,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
      ),
    );
  }
}

class _BuilderBody extends StatelessWidget {
  const _BuilderBody({
    required this.controller,
    required this.title,
    required this.description,
    required this.dayTitles,
    required this.daySummaries,
    required this.onCreate,
    required this.onLeave,
    required this.onAddBlock,
  });

  final PlanBuilderController controller;
  final TextEditingController title;
  final TextEditingController description;
  final Map<String, TextEditingController> dayTitles;
  final Map<String, TextEditingController> daySummaries;
  final Future<void> Function() onCreate;
  final Future<void> Function() onLeave;
  final Future<void> Function(
    PlanBuilderController controller,
    PlanDay day, {
    ExerciseBlock? existing,
    int? index,
  }) onAddBlock;

  @override
  Widget build(BuildContext context) {
    final steps = controller.steps;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            key: const Key('plan-builder-stepper'),
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final visual = controller.visualAt(index);
              final expanded = index == controller.currentStepIndex;
              return _StepCard(
                index: index,
                last: index == steps.length - 1,
                step: step,
                visual: visual,
                expanded: expanded,
                subtitle: subtitleForStep(
                  step: step,
                  plan: controller.plan,
                  visual: visual,
                ),
                onOpen: () => controller.openStep(index),
                child: expanded ? _stepContent(context, step) : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OutlinedButton.icon(
            key: const Key('add-another-day'),
            onPressed: controller.addDay,
            icon: const Icon(Icons.add),
            label: const Text('Add another day'),
          ),
        ),
      ],
    );
  }

  Widget _stepContent(BuildContext context, BuilderStep step) {
    switch (step.kind) {
      case BuilderStepKind.details:
        return _PlanDetailsStep(
          controller: controller,
          title: title,
          description: description,
        );
      case BuilderStepKind.day:
        final day = controller.plan.days.firstWhere(
          (item) => item.dayId == step.dayId,
        );
        return _DayStep(
          controller: controller,
          day: day,
          title: dayTitles[day.dayId]!,
          summary: daySummaries[day.dayId]!,
          onAddBlock: onAddBlock,
        );
      case BuilderStepKind.review:
        return _ReviewStep(
          controller: controller,
          onCreate: onCreate,
          onLeave: onLeave,
        );
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.last,
    required this.step,
    required this.visual,
    required this.expanded,
    required this.subtitle,
    required this.onOpen,
    this.child,
  });

  final int index;
  final bool last;
  final BuilderStep step;
  final BuilderStepVisual visual;
  final bool expanded;
  final String subtitle;
  final VoidCallback onOpen;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incomplete = visual == BuilderStepVisual.incomplete;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _StepGlyph(index: index, visual: visual),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              key: Key('step-${step.key}'),
              color: expanded
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: expanded
                      ? theme.colorScheme.primary
                      : incomplete
                          ? Colors.amber.shade700
                          : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: onOpen,
                    title: AppText(step.title, style: dataTextStyle),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        color: incomplete
                            ? Colors.amber.shade800
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (incomplete && !expanded)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              label: const Text('Needs attention'),
                              backgroundColor: Colors.amber.shade50,
                            ),
                          ),
                        Icon(
                          expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                  if (child != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: child,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepGlyph extends StatelessWidget {
  const _StepGlyph({required this.index, required this.visual});

  final int index;
  final BuilderStepVisual visual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = '${index + 1}';
    late final Color background;
    late final Color foreground;
    late final Widget child;
    late final String semantics;
    switch (visual) {
      case BuilderStepVisual.complete:
        background = theme.colorScheme.primary;
        foreground = theme.colorScheme.onPrimary;
        child = const Icon(Icons.check, size: 18);
        semantics = 'Complete';
      case BuilderStepVisual.current:
        background = theme.colorScheme.primary;
        foreground = theme.colorScheme.onPrimary;
        child = Text(number, style: const TextStyle(fontWeight: FontWeight.bold));
        semantics = 'Current step $number';
      case BuilderStepVisual.incomplete:
        background = Colors.amber.shade700;
        foreground = Colors.white;
        child = const Icon(Icons.priority_high, size: 18);
        semantics = 'Incomplete';
      case BuilderStepVisual.untouched:
        background = theme.colorScheme.surfaceContainerHighest;
        foreground = theme.colorScheme.onSurfaceVariant;
        child = Text(number);
        semantics = 'Not started step $number';
    }
    return Semantics(
      label: semantics,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: IconTheme(
          data: IconThemeData(color: foreground, size: 18),
          child: DefaultTextStyle(
            style: TextStyle(color: foreground, fontSize: 13),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PlanDetailsStep extends StatelessWidget {
  const _PlanDetailsStep({
    required this.controller,
    required this.title,
    required this.description,
  });

  final PlanBuilderController controller;
  final TextEditingController title;
  final TextEditingController description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('plan-name-field'),
          label: 'Plan name *',
          helperText: 'This name appears on your Plans screen.',
          controller: title,
          textInputAction: TextInputAction.next,
          onChanged: controller.setTitle,
        ),
        AppTextField(
          key: const Key('plan-description-field'),
          label: 'Description (optional)',
          controller: description,
          maxLines: 3,
          maxLength: 120,
          onChanged: controller.setDescription,
        ),
        const AppText('Goals (optional)', style: dataTextStyle),
        Text(
          'Choose one or more',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final goal in planGoals)
              FilterChip(
                key: Key('goal-${goal.id}'),
                label: Text(goal.label),
                selected: controller.plan.goalIds.contains(goal.id),
                onSelected: (_) => controller.toggleGoal(goal.id),
                avatar: controller.plan.goalIds.contains(goal.id)
                    ? const Icon(Icons.check, size: 16)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          child: const ListTile(
            leading: Icon(Icons.calendar_month_outlined),
            title: Text(
              'Training days are counted automatically as you add them.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('continue-plan-details'),
          onPressed: () {
            if (controller.plan.title.trim().isEmpty) {
              SemanticsService.announce(
                'Add a plan name.',
                TextDirection.ltr,
              );
              controller.refresh();
              return;
            }
            controller.continueFromCurrent();
          },
          child: const Text('CONTINUE'),
        ),
      ],
    );
  }
}

class _DayStep extends StatelessWidget {
  const _DayStep({
    required this.controller,
    required this.day,
    required this.title,
    required this.summary,
    required this.onAddBlock,
  });

  final PlanBuilderController controller;
  final PlanDay day;
  final TextEditingController title;
  final TextEditingController summary;
  final Future<void> Function(
    PlanBuilderController controller,
    PlanDay day, {
    ExerciseBlock? existing,
    int? index,
  }) onAddBlock;

  @override
  Widget build(BuildContext context) {
    final issues = issuesForDay(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Day name',
          controller: title,
          onChanged: (value) => controller.setDayTitle(day.dayId, value),
        ),
        AppTextField(
          label: 'Summary (optional)',
          controller: summary,
          maxLines: 2,
          onChanged: (value) => controller.setDaySummary(day.dayId, value),
        ),
        if (day.blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: AppText(
              'Add at least one exercise.',
              style: subtitleTextStyle,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: day.blocks.length,
            onReorder: (oldIndex, newIndex) =>
                controller.reorderBlocks(day.dayId, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final block = day.blocks[index];
              return _BuilderBlockCard(
                key: Key('builder-block-${block.blockId}'),
                block: block,
                onEdit: () => onAddBlock(
                  controller,
                  day,
                  existing: block,
                  index: index,
                ),
                onDelete: () {
                  final blocks = List<ExerciseBlock>.from(day.blocks)
                    ..removeAt(index);
                  controller.setDayBlocks(day.dayId, blocks);
                },
              );
            },
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: Key('add-exercise-${day.dayId}'),
          onPressed: () => onAddBlock(controller, day),
          icon: const Icon(Icons.add),
          label: const Text('Add exercise or superset'),
        ),
        if (controller.plan.days.length > 1)
          TextButton(
            onPressed: () => controller.deleteDay(day.dayId),
            child: const Text('Delete day'),
          ),
        const SizedBox(height: 8),
        FilledButton(
          key: Key('continue-day-${day.dayId}'),
          onPressed: () {
            if (issues.isNotEmpty) {
              SemanticsService.announce(
                issues.first.message,
                TextDirection.ltr,
              );
              controller.refresh();
              return;
            }
            controller.continueFromCurrent();
          },
          child: const Text('CONTINUE'),
        ),
      ],
    );
  }
}

class _BuilderBlockCard extends StatelessWidget {
  const _BuilderBlockCard({
    super.key,
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  final ExerciseBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuperset = block.kind == BlockKind.superset;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isSuperset ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSuperset)
              Text(
                'SUPERSET',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            for (final exercise in block.exercises) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExerciseMediaThumbnail(block: block, size: 48),
                title: Text(exercise.title),
                subtitle: Text(formatLoad(exercise)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit ${exercise.title}',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete block',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
                onTap: onEdit,
              ),
              TargetAreaChips(
                selectedIds: exercise.targetAreaIds,
                readOnly: true,
                onChanged: (_) => onEdit(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.controller,
    required this.onCreate,
    required this.onLeave,
  });

  final PlanBuilderController controller;
  final Future<void> Function() onCreate;
  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    final plan = controller.plan;
    final issues = requiredIssuesFor(plan);
    final guidance = catalog.goalGuidanceFor(plan);
    final ready = issues.isEmpty;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(plan.displayTitle, style: titleTextStyle),
        AppText(
          '${plan.days.length} training '
          '${plan.days.length == 1 ? 'day' : 'days'} · '
          '${totalExerciseCount(plan)} '
          '${totalExerciseCount(plan) == 1 ? 'exercise' : 'exercises'}',
          style: subtitleTextStyle,
        ),
        const SizedBox(height: 12),
        for (final day in plan.days) _reviewDay(context, day, issues),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.amber.shade800),
              title: Text(
                issues.length == 1
                    ? '1 item still needs attention. ${issues.first.message}'
                    : '${issues.length} items still need attention.',
              ),
            ),
          ),
        ],
        if (guidance.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final note in guidance)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: Text(note.message),
              trailing: TextButton(
                onPressed: () => _openStepKey(note.stepKey),
                child: const Text('Open day'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('create-plan'),
          onPressed: ready ? onCreate : null,
          child: const Text('CREATE PLAN'),
        ),
        TextButton(
          key: const Key('exit-for-now'),
          onPressed: onLeave,
          child: const Text('EXIT FOR NOW'),
        ),
        Text(
          'Your draft is saved automatically. You can finish it later.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _reviewDay(
    BuildContext context,
    PlanDay day,
    List<PlanIssue> issues,
  ) {
    final dayIssues = [for (final issue in issues) if (issue.stepKey == day.dayId) issue];
    final complete = dayIssues.isEmpty && day.blocks.isNotEmpty;
    final areas = uniqueTargetAreaIdsForDay(day);
    return Card(
      child: ListTile(
        leading: Icon(
          complete ? Icons.check_circle : Icons.error_outline,
          color: complete ? Colors.green : Colors.amber.shade800,
        ),
        title: Text(day.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complete
                  ? _dayCountsLabel(day)
                  : (dayIssues.isEmpty
                      ? 'No exercises added'
                      : dayIssues.first.message),
            ),
            if (areas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final id in areas)
                      Chip(label: Text(targetAreaLabel(id))),
                  ],
                ),
              ),
          ],
        ),
        trailing: complete
            ? TextButton(
                onPressed: () => _openStepKey(day.dayId),
                child: const Text('Edit'),
              )
            : OutlinedButton(
                key: Key('fix-${day.dayId}'),
                onPressed: () => _openStepKey(day.dayId),
                child: const Text('Fix this'),
              ),
      ),
    );
  }

  String _dayCountsLabel(PlanDay day) {
    var exercises = 0;
    var supersets = 0;
    for (final block in day.blocks) {
      if (block.kind == BlockKind.superset) {
        supersets += 1;
      }
      exercises += block.exercises.length;
    }
    final parts = <String>[
      '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}',
    ];
    if (supersets > 0) {
      parts.add('$supersets ${supersets == 1 ? 'superset' : 'supersets'}');
    }
    return parts.join(' · ');
  }

  void _openStepKey(String key) {
    final steps = controller.steps;
    final index = steps.indexWhere((step) => step.key == key);
    if (index >= 0) controller.openStep(index);
  }
}
