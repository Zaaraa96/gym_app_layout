import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../data/app_ports.dart';
import '../../domain/models/models.dart';
import '../../domain/plan_repository.dart';
import 'day_step_body.dart';
import 'exercise_editor_page.dart';

class DayEditorArgs {
  const DayEditorArgs({
    required this.planId,
    required this.dayId,
  });

  /// [WorkoutPlan.uuid], not a local row key.
  final String planId;
  final String dayId;
}

/// Edit one day's title, summary, and exercise blocks.
///
/// Layout matches the Create plan Day step so add/edit/delete/reorder feel
/// the same after a plan is already active.
class DayEditorPage extends StatefulWidget {
  const DayEditorPage({
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
  State<DayEditorPage> createState() => _DayEditorPageState();
}

class _DayEditorPageState extends State<DayEditorPage> {
  PlanRepository get _plans => widget.ports.plans;
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  WorkoutPlan? _plan;
  PlanDay? _day;
  bool _loading = true;
  String? _error;
  int _loadId = 0;

  List<ExerciseBlock> get _blocks => _day?.blocks ?? const [];

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
      if (day != null) {
        if (_titleController.text != day.title) {
          _titleController.text = day.title;
        }
        if (_summaryController.text != day.summary) {
          _summaryController.text = day.summary;
        }
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

  Future<bool> _persistDay(PlanDay updated) async {
    final plan = _plan;
    if (plan == null) return false;
    plan.days = [
      for (final item in plan.days)
        if (item.dayId == updated.dayId) updated else item,
    ];
    try {
      await _plans.save(plan);
      await _load();
      return true;
    } catch (_) {
      return false;
    }
  }

  PlanDay _draftDay(List<ExerciseBlock> blocks) {
    final day = _day!;
    final title = _titleController.text.trim();
    return PlanDay.create(
      dayId: day.dayId,
      title: title.isEmpty ? day.title : title,
      summary: _summaryController.text.trim(),
      blocks: blocks,
    );
  }

  Future<bool> _persistBlocks(List<ExerciseBlock> blocks) async {
    if (_day == null) return false;
    return _persistDay(_draftDay(blocks));
  }

  Future<void> _persistFields() async {
    if (_day == null) return;
    await _persistDay(_draftDay(List<ExerciseBlock>.from(_blocks)));
  }

  Future<void> _done() async {
    await _persistFields();
    if (!mounted) return;
    Get.back();
  }

  Future<void> _addOrEditBlock({ExerciseBlock? existing, int? index}) async {
    if (_day == null) return;
    final day = _day!;
    await showExerciseEditor(
      context,
      existing: existing,
      goalIds: _plan?.goalIds ?? const [],
      dayLabel: day.title,
      onSave: (block) async {
        final blocks = List<ExerciseBlock>.from(_blocks);
        if (index == null) {
          blocks.add(block);
        } else {
          blocks[index] = block;
        }
        return _persistBlocks(blocks);
      },
      onDelete: existing == null || index == null
          ? null
          : () {
              final blocks = List<ExerciseBlock>.from(_blocks)..removeAt(index);
              return _persistBlocks(blocks);
            },
    );
  }

  Future<void> _deleteBlock(int index) async {
    if (_day == null) return;
    final blocks = List<ExerciseBlock>.from(_blocks)..removeAt(index);
    await _persistBlocks(blocks);
  }

  Future<void> _moveBlock(int from, int to) async {
    if (_day == null) return;
    final blocks = List<ExerciseBlock>.from(_blocks);
    final item = blocks.removeAt(from);
    blocks.insert(to, item);
    await _persistBlocks(blocks);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _day != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _done,
        ),
        title: Text(
          _day?.title ?? 'Day',
          style: titleTextStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _error != null && !ready
          ? AppLoadError(message: _error!, onRetry: _retry)
          : _loading && !ready
              ? const Center(child: CircularProgressIndicator())
              : !ready
                  ? const Center(
                      child: AppText('This day is no longer here.'),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        DayStepBody(
                          day: _day!,
                          title: _titleController,
                          summary: _summaryController,
                          onTitleChanged: (_) {},
                          onSummaryChanged: (_) {},
                          onAddExercise: () => _addOrEditBlock(),
                          onEditBlock: (index) => _addOrEditBlock(
                            existing: _day!.blocks[index],
                            index: index,
                          ),
                          onDeleteBlock: _deleteBlock,
                          onMoveUp: (index) => _moveBlock(index, index - 1),
                          onMoveDown: (index) => _moveBlock(index, index + 1),
                          addExerciseKey: const Key('add-exercise'),
                          continueLabel: 'Done',
                          continueKey: const Key('save-day'),
                          onContinue: _done,
                        ),
                      ],
                    ),
    );
  }
}
