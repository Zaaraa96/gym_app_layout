import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/models/models.dart';
import '../../data/plan_repository.dart';
import 'block_summary.dart';

class ImportPreviewArgs {
  const ImportPreviewArgs({required this.fileName, required this.plan});

  final String fileName;
  final WorkoutPlan plan;
}

/// Confirm a parsed import before it is written to Isar.
class ImportPreviewPage extends StatefulWidget {
  const ImportPreviewPage({
    super.key,
    required this.fileName,
    required this.plan,
  });

  final String fileName;
  final WorkoutPlan plan;

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Get.find<PlanRepository>().save(widget.plan);
      if (!mounted) return;
      await Get.offAllNamed(AppRoutes.plan, arguments: widget.plan.uuid);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save plan: $error')),
      );
    }
  }

  void _cancel() {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return AppScaffold(
      appbar: AppBar(
        title: AppText('Import preview', style: titleTextStyle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                AppText(widget.fileName, style: subtitleTextStyle),
                const SizedBox(height: 8),
                AppText(plan.title, style: titleTextStyle),
                const SizedBox(height: 16),
                ...plan.days.map(_dayTile),
                if (plan.commonSections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const AppText('Common sections', style: dataTextStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final section in plan.commonSections)
                        Chip(label: Text(section.title)),
                    ],
                  ),
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
                    outlined: true,
                    data: 'Cancel',
                    onPressed: _cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppElevatedButton(
                    data: 'Save plan',
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTile(PlanDay day) {
    return ExpansionTile(
      initiallyExpanded: true,
      title: AppText(day.title, style: dataTextStyle),
      subtitle: AppText(
        '${day.blocks.length} '
        '${day.blocks.length == 1 ? 'block' : 'blocks'}',
        style: subtitleTextStyle,
      ),
      children: [
        for (final block in day.blocks)
          ListTile(
            dense: true,
            title: AppText(formatBlock(block), style: dataTextStyle),
          ),
      ],
    );
  }
}
