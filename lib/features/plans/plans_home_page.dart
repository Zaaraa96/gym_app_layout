import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/app_ports.dart';
import '../../domain/models/workout_plan.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/plan_repository.dart';
import '../../domain/session_repository.dart';
import '../catalog/exercises_tab.dart';
import '../progress/month_tab.dart';
import '../workout/start_workout.dart';
import 'plan_import_flow.dart';
import '../../domain/today_suggestion.dart';

/// Landing screen for returning users: today, the plan list, Plans | Exercises | Month.
class PlansHomePage extends StatefulWidget {
  const PlansHomePage({super.key, required this.ports});

  final AppPorts ports;

  @override
  State<PlansHomePage> createState() => _PlansHomePageState();
}

class _PlansHomePageState extends State<PlansHomePage> {
  PlanRepository get _plans => widget.ports.plans;
  SessionRepository get _sessions => widget.ports.sessions;

  List<WorkoutPlan> _items = const [];
  WorkoutSession? _live;
  TodaySuggestion? _today;
  bool _loading = true;
  String? _error;
  int _tab = 0;
  int _loadId = 0;
  StreamSubscription<void>? _planWatch;
  StreamSubscription<void>? _sessionWatch;

  @override
  void initState() {
    super.initState();
    _load();
    _planWatch = _plans.watch().listen((_) => _load());
    _sessionWatch = _sessions.watch().listen((_) => _load());
  }

  @override
  void dispose() {
    _planWatch?.cancel();
    _sessionWatch?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final overview = await loadHomeOverview(
        plans: _plans,
        sessions: _sessions,
      );
      if (!mounted || id != _loadId) return;
      setState(() {
        _items = overview.plans;
        _live = overview.live;
        _today = overview.today;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) {
          _error = 'Could not load plans.';
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

  static const _plansTab = 0;
  static const _exercisesTab = 1;
  static const _monthTab = 2;

  String get _title {
    switch (_tab) {
      case _plansTab:
        return 'Plans';
      case _exercisesTab:
        return 'Exercises';
      case _monthTab:
        return 'Month';
      default:
        return 'Plans';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appbar: AppBar(
        title: AppText(_title, style: titleTextStyle),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _plansTabBody(),
          ExercisesTab(ports: widget.ports),
          MonthTab(ports: widget.ports),
        ],
      ),
      floatingActionButton: _tab == _exercisesTab
          ? FloatingActionButton(
              key: const Key('add-catalog-exercise'),
              tooltip: 'Add exercise',
              onPressed: () => Get.toNamed(AppRoutes.editCatalogExercise),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Month',
          ),
        ],
      ),
    );
  }

  Widget _plansTabBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return AppLoadError(message: _error!, onRetry: _retry);
    }
    return Column(
      children: [
        Expanded(
          child: _items.isEmpty && _live == null
              ? _empty()
              : ListView(
                  children: [
                    if (_live != null) _continueBanner(_live!),
                    if (_today != null) _todayCard(_today!),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const AppText('Your plans', style: dataTextStyle),
                      const SizedBox(height: 8),
                      for (var index = 0; index < _items.length; index++) ...[
                        if (index > 0) const Divider(height: 1),
                        _planTile(_items[index]),
                      ],
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: AppElevatedButton(
                  data: 'Import',
                  onPressed: () => startPlanImport(
                    context,
                    import: widget.ports.planImport,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppElevatedButton(
                  outlined: true,
                  data: 'New',
                  onPressed: () => Get.toNamed(AppRoutes.newPlan),
                ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AppElevatedButton(
                    key: const Key('open-starters'),
                    outlined: true,
                    data: 'Beginner',
                    onPressed: () => Get.toNamed(AppRoutes.starters),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppText(
            'No plans yet. Start with a beginner template, import one, or create your first.',
            style: subtitleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppElevatedButton(
            key: const Key('open-starters'),
            data: 'Start with a beginner plan',
            onPressed: () => Get.toNamed(AppRoutes.starters),
          ),
        ],
      ),
    );
  }

  Widget _continueBanner(WorkoutSession live) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        key: const Key('continue-banner'),
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          title: const AppText('Continue workout', style: dataTextStyle),
          subtitle: AppText(
            live.dayTitleSnapshot,
            style: subtitleTextStyle,
          ),
          trailing: const Icon(Icons.play_arrow),
          onTap: () => openLiveSession(live.uuid, widget.ports),
        ),
      ),
    );
  }

  Widget _todayCard(TodaySuggestion today) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        key: const Key('today-card'),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(today.headline, style: titleTextStyle),
              const SizedBox(height: 6),
              AppText(today.prompt, style: subtitleTextStyle),
              const SizedBox(height: 12),
              AppElevatedButton(
                data: today.alreadyTrainedToday
                    ? 'Start next day'
                    : "Start today's workout",
                onPressed: () => startWorkout(
                  context: context,
                  plan: today.plan,
                  day: today.day,
                  start: widget.ports.startSession,
                  ports: widget.ports,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planTile(WorkoutPlan plan) {
    if (plan.isDraft) {
      return ListTile(
        key: Key('draft-tile-${plan.uuid}'),
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Flexible(
              child: AppText(plan.displayTitle, style: dataTextStyle),
            ),
            const SizedBox(width: 8),
            Chip(
              key: Key('draft-badge-${plan.uuid}'),
              label: const Text('Draft'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        subtitle: AppText(
          '${plan.days.length} '
          '${plan.days.length == 1 ? 'day' : 'days'}',
          style: subtitleTextStyle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: Key('resume-draft-${plan.uuid}'),
              onPressed: () => _resumeDraft(plan),
              child: const Text('Resume'),
            ),
            TextButton(
              key: Key('delete-draft-${plan.uuid}'),
              onPressed: () => _deleteDraft(plan),
              child: const Text('Delete'),
            ),
          ],
        ),
        onTap: () => _resumeDraft(plan),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: AppText(plan.displayTitle, style: dataTextStyle),
      subtitle: AppText(
        '${plan.days.length} '
        '${plan.days.length == 1 ? 'day' : 'days'}',
        style: subtitleTextStyle,
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Get.toNamed(
        AppRoutes.plan,
        arguments: plan.uuid,
      ),
    );
  }

  void _resumeDraft(WorkoutPlan plan) {
    Get.toNamed(AppRoutes.newPlan, arguments: plan.uuid);
  }

  Future<void> _deleteDraft(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: Text(
          '“${plan.displayTitle}” will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-draft'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _plans.delete(plan.id);
  }
}
