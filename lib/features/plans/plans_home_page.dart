import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_text.dart';
import '../../data/models/workout_plan.dart';
import '../../data/plan_repository.dart';
import '../welcome/welcome_page.dart';

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
  int _tab = 0;
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
    final items = await _plans.all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
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
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => showImportComingSoon(context),
                    child: const Text('Import'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.newPlan),
                    child: const Text('New'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
