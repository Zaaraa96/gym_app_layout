import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/models/workout_plan.dart';
import '../../data/plan_repository.dart';
import 'plan_import_flow.dart';

/// Landing screen for returning users: the plan list plus the Plans | Month bar.
class PlansHomePage extends StatefulWidget {
  const PlansHomePage({super.key});

  @override
  State<PlansHomePage> createState() => _PlansHomePageState();
}

class _PlansHomePageState extends State<PlansHomePage> {
  final PlanRepository _plans = Get.find<PlanRepository>();

  List<WorkoutPlan> _items = const [];
  bool _loading = true;
  String? _error;
  int _tab = 0;
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
      final items = await _plans.all();
      if (!mounted || id != _loadId) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appbar: AppBar(
        title: AppText(_tab == 0 ? 'Plans' : 'Month', style: titleTextStyle),
      ),
      body: _tab == 0 ? _plansTab() : const _MonthPlaceholder(),
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Month',
          ),
        ],
      ),
    );
  }

  Widget _plansTab() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return AppLoadError(message: _error!, onRetry: _retry);
    }
    return Column(
      children: [
        Expanded(
          child: _items.isEmpty
              ? const Center(
                  child: AppText(
                    'No plans yet. Import one or create your first.',
                    style: subtitleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final plan = _items[index];
                    return ListTile(
                      title: AppText(plan.title, style: dataTextStyle),
                      subtitle: AppText(
                        '${plan.days.length} '
                        '${plan.days.length == 1 ? 'day' : 'days'}',
                        style: subtitleTextStyle,
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => Get.toNamed(
                        AppRoutes.plan,
                        arguments: plan.id,
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: AppElevatedButton(
                  data: 'Import',
                  onPressed: () => startPlanImport(context),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthPlaceholder extends StatelessWidget {
  const _MonthPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppText(
        'The month calendar arrives with session logging.',
        style: subtitleTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
