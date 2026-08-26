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
  const DayEditorArgs({
    required this.planId,
    this.dayId,
    this.sectionId,
  }) : assert(dayId != null || sectionId != null);

  final int planId;
  final String? dayId;
  final String? sectionId;
}

/// Edit one day's (or common section's) title, summary, and exercise blocks.
class DayEditorPage extends StatefulWidget {
  const DayEditorPage({
    super.key,
    required this.planId,
    this.dayId,
    this.sectionId,
  }) : assert(dayId != null || sectionId != null);

  final int planId;
  final String? dayId;
  final String? sectionId;

  bool get isCommonSection => sectionId != null;

  @override
  State<DayEditorPage> createState() => _DayEditorPageState();
}

class _DayEditorPageState extends State<DayEditorPage> {
  final PlanRepository _plans = Get.find<PlanRepository>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  WorkoutPlan? _plan;
  PlanDay? _day;
  CommonSection? _section;
  bool _loading = true;
  String? _error;
  int _loadId = 0;

  bool get _isSection => widget.isCommonSection;

  List<ExerciseBlock> get _blocks =>
      _isSection ? (_section?.blocks ?? const []) : (_day?.blocks ?? const []);

  String get _heading =>
      _isSection ? (_section?.title ?? 'Section') : (_day?.title ?? 'Day');

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
      CommonSection? section;
      if (plan != null) {
        if (_isSection) {
          for (final item in plan.commonSections) {
            if (item.sectionId == widget.sectionId) {
              section = item;
              break;
            }
          }
        } else {
          for (final item in plan.days) {
            if (item.dayId == widget.dayId) {
              day = item;
              break;
            }
          }
        }
      }
      if (!mounted || id != _loadId) return;
      if (section != null) {
        _titleController.text = section.title;
      } else if (day != null) {
        _titleController.text = day.title;
        _summaryController.text = day.summary;
      }
      setState(() {
        _plan = plan;
        _day = day;
        _section = section;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_day == null && _section == null) {
          _error = _isSection
              ? 'Could not load this section.'
              : 'Could not load this day.';
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

  Future<void> _persistBlocks(List<ExerciseBlock> blocks) async {
    if (_isSection) {
      final section = _section;
      if (section == null) return;
      await _persistSection(
        CommonSection.create(
          sectionId: section.sectionId,
          title: _titleController.text.trim().isEmpty
              ? section.title
              : _titleController.text.trim(),
          blocks: blocks,
        ),
      );
      return;
    }
    final day = _day;
    if (day == null) return;
    await _persistDay(
      PlanDay.create(
        dayId: day.dayId,
        title: _titleController.text.trim().isEmpty
            ? day.title
            : _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        blocks: blocks,
      ),
    );
  }

  Future<void> _persistDay(PlanDay updated) async {
    final plan = _plan;
    if (plan == null) return;
    plan.days = [
      for (final item in plan.days)
        if (item.dayId == updated.dayId) updated else item,
    ];
    await _plans.save(plan);
    await _load();
  }

  Future<void> _persistSection(CommonSection updated) async {
    final plan = _plan;
    if (plan == null) return;
    plan.commonSections = [
      for (final item in plan.commonSections)
        if (item.sectionId == updated.sectionId) updated else item,
    ];
    await _plans.save(plan);
    await _load();
  }

  Future<void> _saveAndClose() async {
    await _persistBlocks(List<ExerciseBlock>.from(_blocks));
    if (!mounted) return;
    Get.back();
  }

  Future<void> _addOrEditBlock({ExerciseBlock? existing, int? index}) async {
    if (_day == null && _section == null) return;
    final result = await showExerciseBlockDialog(
      context,
      existing: existing,
    );
    if (result == null) return;
    final blocks = List<ExerciseBlock>.from(_blocks);
    if (index == null) {
      blocks.add(result);
    } else {
      blocks[index] = result;
    }
    await _persistBlocks(blocks);
  }

  Future<void> _deleteBlock(int index) async {
    if (_day == null && _section == null) return;
    final blocks = List<ExerciseBlock>.from(_blocks)..removeAt(index);
    await _persistBlocks(blocks);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _isSection ? _section != null : _day != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _heading,
          style: titleTextStyle,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('add-exercise'),
            tooltip: 'Add exercise',
            onPressed: ready ? () => _addOrEditBlock() : null,
            icon: const Icon(Icons.add),
          ),
          TextButton(
            onPressed: ready ? _saveAndClose : null,
            child: const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: !ready || _blocks.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addOrEditBlock(),
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
      body: _error != null && !ready
          ? AppLoadError(message: _error!, onRetry: _retry)
          : _loading && !ready
              ? const Center(child: CircularProgressIndicator())
              : !ready
                  ? Center(
                      child: AppText(
                        _isSection
                            ? 'This section is no longer here.'
                            : 'This day is no longer here.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                      children: [
                        AppTextField(
                          label: _isSection ? 'section title' : 'day title',
                          controller: _titleController,
                        ),
                        if (!_isSection)
                          AppTextField(
                            label: 'day summary',
                            hint: 'which muscles this day trains…',
                            maxLines: 2,
                            controller: _summaryController,
                          ),
                        const SizedBox(height: 8),
                        if (_blocks.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: AppText(
                              'No exercises yet. Add the first movement.',
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
                          for (var i = 0; i < _blocks.length; i++)
                            _BlockTile(
                              block: _blocks[i],
                              onEdit: () => _addOrEditBlock(
                                existing: _blocks[i],
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
