import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/models.dart';
import '../../domain/new_id.dart';
import '../../domain/plan_catalog.dart';
import '../../domain/plan_repository.dart';
import '../../domain/plan_validation.dart';

enum DraftSaveStatus { saving, saved, failed }

class PlanBuilderController extends ChangeNotifier {
  PlanBuilderController({
    required this.plans,
    required WorkoutPlan plan,
    this.makeId = newId,
    this.clock,
    Duration debounce = const Duration(milliseconds: 500),
  })  : _plan = plan,
        _debounceDuration = debounce,
        currentStepIndex = firstIncompleteStepIndex(plan);

  final PlanRepository plans;
  final String Function() makeId;
  final DateTime Function()? clock;
  final Duration _debounceDuration;

  final WorkoutPlan _plan;
  WorkoutPlan get plan => _plan;

  int currentStepIndex;
  DraftSaveStatus saveStatus = DraftSaveStatus.saved;
  String? saveError;
  Timer? _debounce;
  var _disposed = false;

  List<BuilderStep> get steps => builderStepsFor(_plan);

  BuilderStep get currentStep => steps[currentStepIndex.clamp(0, steps.length - 1)];

  static WorkoutPlan createDraft({
    required String Function() newId,
    DateTime Function()? clock,
  }) {
    final now = (clock ?? DateTime.now)().toUtc();
    return WorkoutPlan.create(
      title: '',
      source: PlanSource.created,
      status: PlanStatus.draft,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(dayId: newId(), title: 'Day 1'),
      ],
    );
  }

  static Future<PlanBuilderController> openNew(PlanRepository plans) async {
    final controller = PlanBuilderController(
      plans: plans,
      plan: createDraft(newId: newId),
    );
    await controller.flush();
    return controller;
  }

  static Future<PlanBuilderController> openExisting(
    PlanRepository plans,
    String uuid,
  ) async {
    final plan = await plans.byUuid(uuid);
    if (plan == null) {
      throw StateError('Plan $uuid is no longer here.');
    }
    return PlanBuilderController(plans: plans, plan: plan);
  }

  BuilderStepVisual visualAt(int index) {
    return visualForStep(
      step: steps[index],
      plan: _plan,
      currentIndex: currentStepIndex,
      stepIndex: index,
    );
  }

  void refresh() => notifyListeners();

  void openStep(int index) {
    if (index < 0 || index >= steps.length) return;
    currentStepIndex = index;
    notifyListeners();
  }

  void continueFromCurrent() {
    currentStepIndex = nextIncompleteStepIndex(_plan, currentStepIndex);
    unawaited(flush());
    notifyListeners();
  }

  void setTitle(String value) {
    _plan.title = value;
    _markDirty();
  }

  void setDescription(String value) {
    _plan.description = value.length <= 120 ? value : value.substring(0, 120);
    _markDirty();
  }

  void toggleGoal(String goalId) {
    final next = List<String>.from(_plan.goalIds);
    if (next.contains(goalId)) {
      next.remove(goalId);
    } else {
      next.add(goalId);
    }
    _plan.goalIds = canonicalizeGoalIds(next);
    _markDirty();
  }

  void setDayTitle(String dayId, String value) {
    _day(dayId)?.title = value;
    _markDirty();
  }

  void setDaySummary(String dayId, String value) {
    _day(dayId)?.summary = value;
    _markDirty();
  }

  void setDayBlocks(String dayId, List<ExerciseBlock> blocks) {
    final day = _day(dayId);
    if (day == null) return;
    day.blocks = blocks;
    _markDirty();
  }

  void reorderBlocks(String dayId, int oldIndex, int newIndex) {
    final day = _day(dayId);
    if (day == null) return;
    var to = newIndex;
    if (to > oldIndex) to -= 1;
    final blocks = List<ExerciseBlock>.from(day.blocks);
    final item = blocks.removeAt(oldIndex);
    blocks.insert(to, item);
    day.blocks = blocks;
    _markDirty();
  }

  void addDay() {
    final nextNumber = _plan.days.length + 1;
    _plan.days = [
      ..._plan.days,
      PlanDay.create(dayId: makeId(), title: 'Day $nextNumber'),
    ];
    currentStepIndex = _plan.days.length;
    unawaited(flush());
    notifyListeners();
  }

  void deleteDay(String dayId) {
    if (_plan.days.length <= 1) return;
    final old = List<PlanDay>.from(_plan.days);
    final remaining = <PlanDay>[];
    for (var i = 0; i < old.length; i++) {
      final day = old[i];
      if (day.dayId == dayId) continue;
      if (day.title.trim() == 'Day ${i + 1}') {
        day.title = 'Day ${remaining.length + 1}';
      }
      remaining.add(day);
    }
    _plan.days = remaining;
    currentStepIndex = firstIncompleteStepIndex(_plan);
    unawaited(flush());
    notifyListeners();
  }

  PlanDay? _day(String dayId) {
    for (final day in _plan.days) {
      if (day.dayId == dayId) return day;
    }
    return null;
  }

  void _markDirty() {
    saveStatus = DraftSaveStatus.saving;
    saveError = null;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    _debounce?.cancel();
    saveStatus = DraftSaveStatus.saving;
    saveError = null;
    if (!_disposed) notifyListeners();
    try {
      _plan.title = _plan.title.trim();
      _plan.description = _plan.description.trim();
      if (_plan.status != PlanStatus.active) {
        _plan.status = PlanStatus.draft;
      }
      await plans.save(_plan);
      saveStatus = DraftSaveStatus.saved;
      saveError = null;
    } catch (error) {
      saveStatus = DraftSaveStatus.failed;
      saveError = '$error';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> retrySave() => flush();

  Future<bool> activate() async {
    await flush();
    if (!planCanActivate(_plan)) return false;
    _plan.status = PlanStatus.active;
    try {
      await plans.save(_plan);
      saveStatus = DraftSaveStatus.saved;
      return true;
    } catch (error) {
      _plan.status = PlanStatus.draft;
      saveStatus = DraftSaveStatus.failed;
      saveError = '$error';
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
