import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../data/plan_repository.dart';
import 'block_summary.dart';
import 'exercise_block_dialog.dart';

class DayEditorArgs {
  const DayEditorArgs({required this.planId, required this.dayId});

  final int planId;
  final String dayId;
}

/// Edit one day's title, summary, and exercise blocks.
class DayEditorPage extends StatefulWidget {
  const DayEditorPage({
    super.key,
    required this.planId,
    required this.dayId,
  });

  final int planId;
  final String dayId;

  @override
  State<DayEditorPage> createState() => _DayEditorPageState();
}

class _DayEditorPageState extends State<DayEditorPage> {
  final PlanRepository _plans = Get.find<PlanRepository>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
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

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final plan = await _plans.byId(widget.planId);
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
      if (day != null) {
        _titleController.text = day.title;
        _summaryController.text = day.summary;
      }
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

  PlanDay _dayFromFields(PlanDay day, {List<ExerciseBlock>? blocks}) {
    return PlanDay.create(
      dayId: day.dayId,
      title: _titleController.text.trim().isEmpty
          ? day.title
          : _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      blocks: blocks ?? List<ExerciseBlock>.from(day.blocks),
    );
  }

  Future<void> _persist(PlanDay updated) async {
    final plan = _plan;
    if (plan == null) return;
    plan.days = [
      for (final item in plan.days)
        if (item.dayId == updated.dayId) updated else item,
    ];
    await _plans.save(plan);
    await _load();
  }

  Future<void> _saveAndClose() async {
    final day = _day;
    if (day != null) {
      await _persist(_dayFromFields(day));
    }
    if (!mounted) return;
    Get.back();
  }

  Future<void> _addOrEditBlock({ExerciseBlock? existing, int? index}) async {
    final day = _day;
    if (day == null) return;
    final result = await showExerciseBlockDialog(
      context,
      existing: existing,
    );
    if (result == null) return;
    final blocks = List<ExerciseBlock>.from(day.blocks);
    if (index == null) {
      blocks.add(result);
    } else {
      blocks[index] = result;
    }
    await _persist(_dayFromFields(day, blocks: blocks));
  }

  Future<void> _deleteBlock(int index) async {
    final day = _day;
    if (day == null) return;
    final blocks = List<ExerciseBlock>.from(day.blocks)..removeAt(index);
    await _persist(_dayFromFields(day, blocks: blocks));
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    return Scaffold(
      appBar: AppBar(
        title: AppText(day?.title ?? 'Day', style: titleTextStyle),
        actions: [
          IconButton(
            key: const Key('add-exercise'),
            tooltip: 'Add exercise',
            onPressed: day == null ? null : () => _addOrEditBlock(),
            icon: const Icon(Icons.add),
          ),
          TextButton(
            onPressed: day == null ? null : _saveAndClose,
            child: const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: day == null || day.blocks.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addOrEditBlock(),
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
      body: _error != null && day == null
          ? AppLoadError(message: _error!, onRetry: _retry)
          : _loading && day == null
              ? const Center(child: CircularProgressIndicator())
              : day == null
                  ? const Center(child: AppText('This day is no longer here.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                      children: [
                        AppTextField(
                          label: 'day title',
                          controller: _titleController,
                        ),
                        AppTextField(
                          label: 'day summary',
                          hint: 'which muscles this day trains…',
                          maxLines: 2,
                          controller: _summaryController,
                        ),
                        const SizedBox(height: 8),
                        if (day.blocks.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: AppText(
                              'No exercises yet. Add the first movement for this day.',
                              style: subtitleTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _addOrEditBlock(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add exercise'),
                          ),
                        ] else
                          for (var i = 0; i < day.blocks.length; i++)
                            _BlockTile(
                              block: day.blocks[i],
                              onEdit: () => _addOrEditBlock(
                                existing: day.blocks[i],
                                index: i,
                              ),
                              onDelete: () => _deleteBlock(i),
                            ),
                      ],
                    ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onEdit,
        title: AppText(formatBlock(block), style: dataTextStyle),
        subtitle: AppText(
          block.kind == BlockKind.superset ? 'Superset' : 'Single',
          style: subtitleTextStyle,
        ),
        trailing: IconButton(
          tooltip: 'Delete exercise',
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
