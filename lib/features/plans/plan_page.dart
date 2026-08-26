import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../data/new_id.dart';
import '../../data/plan_repository.dart';
import 'block_summary.dart';
import 'day_editor_page.dart';
import 'day_preview_page.dart';

/// One plan: rename it, add days, open a day to edit its workout.
class PlanPage extends StatefulWidget {
  const PlanPage({super.key, required this.planId});

  final int planId;

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final PlanRepository _plans = Get.find<PlanRepository>();
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
      final plan = await _plans.byId(widget.planId);
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
    controller.dispose();
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
      () => DayPreviewPage(planId: widget.planId, dayId: day.dayId),
      routeName: AppRoutes.day,
    );
    await _load();
  }

  Future<void> _openEditor(PlanDay day) async {
    await Get.to(
      () => DayEditorPage(planId: widget.planId, dayId: day.dayId),
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
        title: AppText(plan?.title ?? 'Plan', style: titleTextStyle),
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
    if (plan.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      itemCount: plan.days.length,
      itemBuilder: (context, index) {
        final day = plan.days[index];
        return _DayCard(
          key: Key('day-card-${day.dayId}'),
          day: day,
          index: index,
          onOpen: () => _openDay(day),
          onDelete: () => _deleteDay(day),
        );
      },
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
