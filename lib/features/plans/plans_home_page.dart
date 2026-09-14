import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/app_theme.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/cuelift_brand.dart';
import '../../common/widgets/theme_mode_button.dart';
import '../../data/app_ports.dart';
import '../../domain/models/models.dart';
import '../../domain/once_plan_cycle.dart';
import '../../domain/plan_repository.dart';
import '../../domain/session_repository.dart';
import '../../domain/skip_repository.dart';
import '../../domain/today_suggestion.dart';
import '../catalog/exercises_tab.dart';
import '../progress/month_tab.dart';
import '../workout/start_workout.dart';
import 'plan_import_flow.dart';
import 'reminder_settings_sheet.dart';

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
  SkipRepository get _skips => widget.ports.skips;

  List<WorkoutPlan> _items = const [];
  WorkoutSession? _live;
  List<TodayItem> _todayItems = const [];
  bool _loading = true;
  String? _error;
  int _tab = 0;
  int _loadId = 0;
  StreamSubscription<void>? _planWatch;
  StreamSubscription<void>? _sessionWatch;
  StreamSubscription<void>? _skipWatch;

  @override
  void initState() {
    super.initState();
    _load();
    _planWatch = _plans.watch().listen((_) => _load());
    _sessionWatch = _sessions.watch().listen((_) => _load());
    _skipWatch = _skips.watch().listen((_) => _load());
  }

  @override
  void dispose() {
    _planWatch?.cancel();
    _sessionWatch?.cancel();
    _skipWatch?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final overview = await loadHomeOverview(
        plans: _plans,
        sessions: _sessions,
        skips: _skips,
      );
      if (!mounted || id != _loadId) return;
      setState(() {
        _items = overview.plans;
        _live = overview.live;
        _todayItems = overview.todayItems;
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

  bool get _hasOnSchedule => _items.any((p) => p.feedsToday);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appbar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CueLiftAppMark(size: 28),
        ),
        leadingWidth: 44,
        title: AppText(_title, style: titleTextStyle),
        actions: [
          IconButton(
            key: const Key('open-reminder-settings'),
            tooltip: 'Workout reminder',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showReminderSettingsSheet(
              context,
              ports: widget.ports,
              workoutDueCount: _todayItems.where((i) => i.isWorkout).length,
            ),
          ),
          const ThemeModeButton(),
        ],
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
        animationDuration: CueLiftMotion.navIndicator,
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
                    _todaySection(),
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

  Widget _todaySection() {
    if (!_hasOnSchedule) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          key: const Key('today-empty-banner'),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText('Nothing on schedule', style: titleTextStyle),
                SizedBox(height: 6),
                AppText(
                  'Import, create, or start a beginner plan and turn On schedule to fill Today.',
                  style: subtitleTextStyle,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_todayItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppText('Today', style: dataTextStyle),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.separated(
              key: const Key('today-list'),
              scrollDirection: Axis.horizontal,
              itemCount: _todayItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _todayItems[index];
                final firstWorkout =
                    _todayItems.indexWhere((i) => i.isWorkout);
                final card = item.isRest
                    ? _restCard(item)
                    : _workoutCard(
                        item,
                        isPrimary: index == firstWorkout,
                      );
                return SizedBox(width: 300, child: card);
              },
            ),
          ),
        ],
      ),
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

  Widget _workoutCard(TodayItem today, {bool isPrimary = false}) {
    final day = today.day!;
    return Material(
      key: isPrimary
          ? const Key('today-card')
          : Key('today-card-${today.plan.uuid}-${day.dayId}'),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              today.plan.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subtitleTextStyle,
            ),
            Text(
              today.headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                today.prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: subtitleTextStyle,
              ),
            ),
            AppElevatedButton(
              key: Key('start-today-${today.plan.uuid}'),
              data: today.alreadyTrainedToday
                  ? 'Start next day'
                  : "Start today's workout",
              onPressed: () => startWorkout(
                context: context,
                plan: today.plan,
                day: day,
                start: widget.ports.startSession,
                ports: widget.ports,
              ),
            ),
            TextButton(
              key: Key('skip-day-${today.plan.uuid}-${day.dayId}'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _skipDay(today),
              child: const Text('Skip day'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _restCard(TodayItem today) {
    return Material(
      key: Key('today-rest-${today.plan.uuid}'),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              today.headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                today.prompt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: subtitleTextStyle,
              ),
            ),
            OutlinedButton(
              key: Key('open-plan-rest-${today.plan.uuid}'),
              onPressed: () => Get.toNamed(
                AppRoutes.plan,
                arguments: today.plan.uuid,
              ),
              child: const Text('Open plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _skipDay(TodayItem today) async {
    final day = today.day;
    if (day == null) return;
    await _skips.save(
      PlanDaySkip.create(
        planId: today.plan.uuid,
        dayId: day.dayId,
        date: DateTime.now(),
      ),
    );
    await parkOncePlanByIdIfFinished(
      planId: today.plan.uuid,
      plans: _plans,
      sessions: _sessions,
      skips: _skips,
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
        '${plan.days.length == 1 ? 'day' : 'days'}'
        '${plan.onSchedule ? '' : ' · Off schedule'}',
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
