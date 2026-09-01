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
import '../../domain/plan_repository.dart';
import 'block_summary.dart';
import 'day_editor_page.dart';
import 'day_preview_page.dart';

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
    final titleController =
        TextEditingController(text: 'Day ${plan.days.length + 1}');
    final summaryController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'day title',
              controller: titleController,
              autofocus: true,
            ),
            AppTextField(
              label: 'day summary',
              hint: 'muscles, focus, notes…',
              maxLines: 2,
              controller: summaryController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save day'),
          ),
        ],
      ),
    );
    final title = titleController.text.trim().isEmpty
        ? 'Day ${plan.days.length + 1}'
        : titleController.text.trim();
    final summary = summaryController.text.trim();
    titleController.dispose();
    summaryController.dispose();
    if (created != true) return;
    final day = PlanDay.create(
      dayId: newId(),
      title: title,
      summary: summary,
    );
    plan.days = [...plan.days, day];
    await _save(plan);
    await _openEditor(day);
  }

  Future<void> _addSection() async {
    final plan = _plan;
    if (plan == null) return;
    final titleController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add common section'),
        content: AppTextField(
          label: 'section title',
          hint: 'abs, corrective…',
          controller: titleController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save section'),
          ),
        ],
      ),
    );
    final title = titleController.text.trim().isEmpty
        ? 'Section ${plan.commonSections.length + 1}'
        : titleController.text.trim();
    titleController.dispose();
    if (created != true) return;
    final section = CommonSection.create(
      sectionId: newId(),
      title: title,
    );
    plan.commonSections = [...plan.commonSections, section];
    await _save(plan);
    await _openSectionEditor(section);
  }

  Future<void> _deleteSection(CommonSection section) async {
    final plan = _plan;
    if (plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this section?'),
        content: Text('"${section.title}" and its exercises will be removed.'),
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
    plan.commonSections = [
      for (final item in plan.commonSections)
        if (item.sectionId != section.sectionId) item,
    ];
    await _save(plan);
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

  Future<void> _openSectionEditor(CommonSection section) async {
    await Get.to(
      () => DayEditorPage(
        planId: widget.planId,
        sectionId: section.sectionId,
        ports: widget.ports,
      ),
      routeName: AppRoutes.editSection,
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
          plan?.title ?? 'Plan',
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
        _commonSections(context, plan),
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
              index: index,
              onOpen: () => _openDay(plan.days[index]),
              onDelete: () => _deleteDay(plan.days[index]),
            ),
      ],
    );
  }

  Widget _commonSections(BuildContext context, WorkoutPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText('Common sections', style: dataTextStyle),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _addSection,
            child: const Text('Add section'),
          ),
        ),
        if (plan.commonSections.isEmpty)
          const AppText(
            'Optional extras like abs. Include them when you start a day.',
            style: subtitleTextStyle,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final section in plan.commonSections)
                InputChip(
                  key: Key('common-section-${section.sectionId}'),
                  label: Text(section.title),
                  onPressed: () => _openSectionEditor(section),
                  onDeleted: () => _deleteSection(section),
                  deleteButtonTooltipMessage: 'Delete section',
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    super.key,
    required this.day,
    required this.index,
    required this.onOpen,
    required this.onDelete,
  });

  final PlanDay day;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onOpen,
            child: ColoredBox(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: Transform.flip(
                      flipX: index == 1,
                      child: Opacity(
                        opacity: 0.8,
                        child: Image.asset(
                          'assets/image/${index % 3}.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.secondaryContainer,
                              theme.colorScheme.tertiaryContainer,
                            ][index % 3],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
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
                        if (day.summary.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width / 3,
                            ),
                            child: AppText(day.summary, style: dataTextStyle),
                          ),
                        if (day.blocks.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          AppText(
                            formatBlock(day.blocks.first),
                            style: dataTextStyle,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                '${day.blocks.length} '
                                '${day.blocks.length == 1 ? 'exercise' : 'exercises'}',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
