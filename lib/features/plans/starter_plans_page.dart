import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/app_ports.dart';
import '../../data/starter_plans.dart';

/// First-run (and empty-home) picker for bundled beginner programs.
class StarterPlansPage extends StatefulWidget {
  const StarterPlansPage({super.key, required this.ports});

  final AppPorts ports;

  @override
  State<StarterPlansPage> createState() => _StarterPlansPageState();
}

class _StarterPlansPageState extends State<StarterPlansPage> {
  String? _busyId;

  Future<void> _install(StarterPlanSpec spec) async {
    if (_busyId != null) return;
    setState(() => _busyId = spec.id);
    try {
      await installStarterPlan(
        spec,
        plans: widget.ports.plans,
      );
      if (!mounted) return;
      await Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busyId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add that plan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appbar: AppBar(
        title: AppText('Beginner plans', style: titleTextStyle),
      ),
      body: ListView(
        children: [
          const AppText(
            'Start with a plan you can do this week. You can edit every '
            'exercise later.',
            style: subtitleTextStyle,
          ),
          const SizedBox(height: 16),
          for (final spec in starterPlans) ...[
            _StarterCard(
              spec: spec,
              busy: _busyId == spec.id,
              enabled: _busyId == null,
              onUse: () => _install(spec),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({
    required this.spec,
    required this.busy,
    required this.enabled,
    required this.onUse,
  });

  final StarterPlanSpec spec;
  final bool busy;
  final bool enabled;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: spec.recommended
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(spec.title, style: titleTextStyle),
              ),
              if (spec.recommended)
                const AppText('Recommended', style: subtitleTextStyle),
            ],
          ),
          const SizedBox(height: 8),
          AppText(spec.blurb, style: subtitleTextStyle),
          const SizedBox(height: 12),
          AppElevatedButton(
            key: Key('use-starter-${spec.id}'),
            data: busy ? 'Adding…' : 'Use this plan',
            onPressed: enabled ? onUse : null,
          ),
        ],
      ),
    );
  }
}
