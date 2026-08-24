import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../data/new_id.dart';
import '../../data/plan_repository.dart';
import 'day_editor_page.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await _plans.byId(widget.planId);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
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
    if (created != true) return;
    final title = titleController.text.trim().isEmpty
        ? 'Day ${plan.days.length + 1}'
        : titleController.text.trim();
    plan.days = [
      ...plan.days,
      PlanDay.create(
        dayId: newId(),
        title: title,
        summary: summaryController.text.trim(),
      ),
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
    await Get.toNamed(
      AppRoutes.editDay,
      arguments: DayEditorArgs(planId: widget.planId, dayId: day.dayId),
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
      body: _loading
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
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      itemCount: plan.days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final day = plan.days[index];
        final tint = [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.tertiaryContainer,
        ][index % 3];
        return Material(
          color: tint,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openDay(day),
            child: SizedBox(
              height: 160,
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          onPressed: () => _deleteDay(day),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    if (day.summary.isNotEmpty)
                      AppText(day.summary, style: dataTextStyle),
                    const Spacer(),
                    AppText(
                      '${day.blocks.length} '
                      '${day.blocks.length == 1 ? 'exercise' : 'exercises'}',
                      style: subtitleTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
