import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/app_routes.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/app_ports.dart';
import '../../domain/catalog_query.dart';
import '../../domain/models/catalog_exercise.dart';
import '../../domain/plan_catalog.dart';
import 'catalog_format.dart';
import 'catalog_media_thumbnail.dart';

/// Home-shell Exercises tab: bundled + user catalog, filterable by region.
class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key, required this.ports});

  final AppPorts ports;

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  final _search = TextEditingController();
  final _selectedRegions = <String>{};
  final _selectedMuscles = <String>{};
  List<CatalogExercise> _all = const [];
  bool _loading = true;
  String? _error;
  StreamSubscription<void>? _watch;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
    _watch = widget.ports.catalog.watch().listen((_) => _load());
  }

  @override
  void dispose() {
    _watch?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await widget.ports.catalog.all();
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_all.isEmpty) _error = 'Could not load exercises.';
      });
    }
  }

  List<CatalogExercise> get _visible => filterCatalogExercises(
        _all,
        query: _search.text,
        regionIds: _selectedRegions,
        targetAreaIds: _selectedMuscles,
      );

  void _toggleRegion(String id) {
    setState(() {
      if (_selectedRegions.contains(id)) {
        _selectedRegions.remove(id);
      } else {
        _selectedRegions.add(id);
      }
    });
  }

  void _toggleMuscle(String id) {
    setState(() {
      if (_selectedMuscles.contains(id)) {
        _selectedMuscles.remove(id);
      } else {
        _selectedMuscles.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _all.isEmpty) {
      return AppLoadError(message: _error!, onRetry: _load);
    }
    final visible = _visible;
    return Column(
      key: const Key('exercises-tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('catalog-search'),
          controller: _search,
          label: 'Search',
          hint: 'Name or alias',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              key: const Key('region-all'),
              label: const Text('All'),
              selected: _selectedRegions.isEmpty,
              onSelected: (_) => setState(() => _selectedRegions.clear()),
            ),
            for (final region in catalogRegions)
              FilterChip(
                key: Key('region-${region.id}'),
                label: Text(region.label),
                selected: _selectedRegions.contains(region.id),
                onSelected: (_) => _toggleRegion(region.id),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final area in targetAreas)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('muscle-${area.id}'),
                    label: Text(area.label),
                    selected: _selectedMuscles.contains(area.id),
                    onSelected: (_) => _toggleMuscle(area.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: AppText(
                    'No exercises match these filters.',
                    style: subtitleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final exercise = visible[index];
                    return ListTile(
                      key: Key('catalog-tile-${exercise.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: CatalogMediaThumbnail(exercise: exercise),
                      title: AppText(exercise.title, style: dataTextStyle),
                      subtitle: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final id in exercise.targetAreaIds.take(3))
                            Chip(
                              label: Text(targetAreaLabel(id)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (exercise.isUserCreated)
                            const Chip(
                              label: Text('Custom'),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      trailing: AppText(
                        formatCatalogPrescription(exercise),
                        style: subtitleTextStyle,
                      ),
                      onTap: () => Get.toNamed(
                        AppRoutes.catalogExercise,
                        arguments: exercise.id,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
