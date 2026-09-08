import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../data/app_ports.dart';
import '../../domain/models/catalog_exercise.dart';
import '../../domain/plan_catalog.dart';
import 'catalog_format.dart';
import 'catalog_media_thumbnail.dart';

/// Read-only catalog movement. Custom entries can be edited or deleted.
class CatalogExerciseDetailPage extends StatefulWidget {
  const CatalogExerciseDetailPage({
    super.key,
    required this.exerciseId,
    required this.ports,
  });

  final String exerciseId;
  final AppPorts ports;

  @override
  State<CatalogExerciseDetailPage> createState() =>
      _CatalogExerciseDetailPageState();
}

class _CatalogExerciseDetailPageState extends State<CatalogExerciseDetailPage> {
  CatalogExercise? _exercise;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exercise = await widget.ports.catalog.byId(widget.exerciseId);
      if (!mounted) return;
      setState(() {
        _exercise = exercise;
        _loading = false;
        _error = exercise == null ? 'Exercise not found.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load exercise.';
      });
    }
  }

  Future<void> _delete() async {
    final exercise = _exercise;
    if (exercise == null || !exercise.isUserCreated) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this exercise?'),
        content: Text(
          '“${exercise.title}” will be removed from your catalog. Plans that '
          'already use it are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-catalog-exercise'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.ports.catalog.deleteUser(exercise.id);
    if (!mounted) return;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;
    return AppScaffold(
      appbar: AppBar(
        title: AppText(
          exercise?.title ?? 'Exercise',
          style: titleTextStyle,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppLoadError(message: _error!, onRetry: _load)
              : exercise == null
                  ? const SizedBox.shrink()
                  : ListView(
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: CatalogMediaThumbnail(
                            exercise: exercise,
                            size: 180,
                            playGif: true,
                            borderRadius: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppText(exercise.title, style: titleTextStyle),
                        const SizedBox(height: 8),
                        AppText(
                          formatCatalogPrescription(exercise),
                          style: subtitleTextStyle,
                        ),
                        const SizedBox(height: 16),
                        const AppText('Regions', style: dataTextStyle),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final id in exercise.regionIds)
                              Chip(label: Text(catalogRegionLabel(id))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const AppText('Target areas', style: dataTextStyle),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final id in exercise.targetAreaIds)
                              Chip(label: Text(targetAreaLabel(id))),
                          ],
                        ),
                        if (exercise.isUserCreated) ...[
                          const SizedBox(height: 24),
                          AppElevatedButton(
                            key: const Key('edit-catalog-exercise'),
                            data: 'Edit',
                            onPressed: () async {
                              await Get.toNamed(
                                AppRoutes.editCatalogExercise,
                                arguments: exercise.id,
                              );
                              await _load();
                            },
                          ),
                          const SizedBox(height: 12),
                          AppElevatedButton(
                            key: const Key('delete-catalog-exercise'),
                            outlined: true,
                            data: 'Delete',
                            onPressed: _delete,
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
    );
  }
}
