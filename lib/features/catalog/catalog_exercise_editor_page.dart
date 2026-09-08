import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/app_elevated_button.dart';
import '../../common/widgets/app_load_error.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../data/app_ports.dart';
import '../../domain/catalog_write.dart';
import '../../domain/models/catalog_exercise.dart';
import '../../domain/models/enums.dart';
import '../../domain/plan_catalog.dart';
import '../plans/exercise_media_picker.dart';
import '../plans/exercise_media_picker_sheet.dart';
import '../plans/target_area_chips.dart';
import 'catalog_media_thumbnail.dart';

/// Add or edit a user-created catalog movement.
class CatalogExerciseEditorPage extends StatefulWidget {
  const CatalogExerciseEditorPage({
    super.key,
    required this.ports,
    this.exerciseId,
  });

  final AppPorts ports;
  final String? exerciseId;

  @override
  State<CatalogExerciseEditorPage> createState() =>
      _CatalogExerciseEditorPageState();
}

class _CatalogExerciseEditorPageState extends State<CatalogExerciseEditorPage> {
  final _title = TextEditingController();
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');
  final _duration = TextEditingController(text: '30');
  PrescriptionType _type = PrescriptionType.reps;
  List<String> _targetAreaIds = [];
  List<String> _regionIds = [];
  bool _regionsTouched = false;
  PickedExerciseMedia? _media;
  CatalogExercise? _existing;
  bool _loading = false;
  String? _error;
  String? _loadError;

  bool get _isEditing => widget.exerciseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loading = true;
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _sets.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final exercise = await widget.ports.catalog.byId(widget.exerciseId!);
      if (!mounted) return;
      if (exercise == null || !exercise.isUserCreated) {
        setState(() {
          _loading = false;
          _loadError = 'Exercise not found.';
        });
        return;
      }
      setState(() {
        _existing = exercise;
        _title.text = exercise.title;
        _targetAreaIds = [...exercise.targetAreaIds];
        _regionIds = [...exercise.regionIds];
        _regionsTouched = true;
        _type = exercise.prescriptionType;
        _sets.text = '${exercise.defaultSets}';
        _reps.text = '${exercise.defaultReps ?? 10}';
        _duration.text = '${exercise.defaultDurationSeconds ?? 30}';
        if (exercise.hasPicture) {
          _media = PickedExerciseMedia(
            uri: exercise.mediaUri,
            source: exercise.mediaSource,
            kind: exercise.mediaKind,
          );
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load exercise.';
      });
    }
  }

  void _onTargetsChanged(List<String> ids) {
    setState(() {
      _targetAreaIds = ids;
      if (!_regionsTouched) {
        _regionIds = defaultRegionIdsFor(ids);
      }
    });
  }

  void _toggleRegion(String id) {
    setState(() {
      _regionsTouched = true;
      if (_regionIds.contains(id)) {
        _regionIds = [for (final item in _regionIds) if (item != id) item];
      } else {
        _regionIds = canonicalizeRegionIds([..._regionIds, id]);
      }
    });
  }

  Future<void> _pickMedia() async {
    final picked = await showExerciseMediaPickerSheet(
      context,
      current: _media,
      titleHint: _title.text,
    );
    if (picked == null || !mounted) return;
    setState(() => _media = picked);
  }

  CatalogExercise _draft() {
    final timed = _type == PrescriptionType.timed;
    final sets = int.tryParse(_sets.text.trim()) ?? 0;
    final reps = int.tryParse(_reps.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    return CatalogExercise(
      id: _existing?.id ?? '',
      localId: _existing?.localId ?? 0,
      title: _title.text,
      regionIds: _regionIds,
      targetAreaIds: _targetAreaIds,
      mediaUri: _media?.uri ?? '',
      mediaSource: _media?.source ?? ExerciseMediaSource.none,
      mediaKind: _media?.kind ?? ExerciseMediaKind.unknown,
      origin: CatalogOrigin.user,
      prescriptionType: _type,
      defaultSets: sets,
      defaultReps: timed ? null : reps,
      defaultDurationSeconds: timed ? duration : null,
      createdAt: _existing?.createdAt,
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    try {
      await widget.ports.catalog.saveUser(_draft());
      if (!mounted) return;
      Get.back();
    } on CatalogWriteException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save exercise. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _draft();
    return AppScaffold(
      appbar: AppBar(
        title: AppText(
          _isEditing ? 'Edit exercise' : 'Add exercise',
          style: titleTextStyle,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? AppLoadError(message: _loadError!, onRetry: _loadExisting)
              : ListView(
                  children: [
                    AppTextField(
                      key: const Key('catalog-exercise-name'),
                      controller: _title,
                      label: 'Exercise name',
                      hint: 'e.g. Cable crunch',
                    ),
                    const SizedBox(height: 8),
                    Text('Picture', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    InkWell(
                      key: const Key('catalog-exercise-picture'),
                      onTap: _pickMedia,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: preview.hasPicture
                            ? Center(
                                child: CatalogMediaThumbnail(
                                  exercise: preview,
                                  size: 96,
                                ),
                              )
                            : const Center(
                                child: AppText(
                                  'Tap to add a picture',
                                  style: subtitleTextStyle,
                                ),
                              ),
                      ),
                    ),
                    TargetAreaChips(
                      selectedIds: _targetAreaIds,
                      onChanged: _onTargetsChanged,
                    ),
                    const SizedBox(height: 8),
                    Text('Regions', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final region in catalogRegions)
                          FilterChip(
                            key: Key('edit-region-${region.id}'),
                            label: Text(region.label),
                            selected: _regionIds.contains(region.id),
                            onSelected: (_) => _toggleRegion(region.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Default prescription',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<PrescriptionType>(
                      segments: const [
                        ButtonSegment(
                          value: PrescriptionType.reps,
                          label: Text('Reps'),
                        ),
                        ButtonSegment(
                          value: PrescriptionType.timed,
                          label: Text('Timed'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (value) {
                        setState(() => _type = value.first);
                      },
                    ),
                    AppTextField(
                      key: const Key('catalog-exercise-sets'),
                      controller: _sets,
                      label: 'Sets',
                      keyboardType: TextInputType.number,
                    ),
                    if (_type == PrescriptionType.reps)
                      AppTextField(
                        key: const Key('catalog-exercise-reps'),
                        controller: _reps,
                        label: 'Reps',
                        keyboardType: TextInputType.number,
                      )
                    else
                      AppTextField(
                        key: const Key('catalog-exercise-duration'),
                        controller: _duration,
                        label: 'Duration (seconds)',
                        keyboardType: TextInputType.number,
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      AppText(
                        _error!,
                        style: subtitleTextStyle.copyWith(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppElevatedButton(
                      key: const Key('save-catalog-exercise'),
                      data: _isEditing ? 'Save changes' : 'Add exercise',
                      onPressed: _save,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}
