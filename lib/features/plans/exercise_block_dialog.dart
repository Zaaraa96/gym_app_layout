import 'package:flutter/material.dart';

import '../../common/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../data/new_id.dart';
import 'exercise_asset_catalog.dart';
import 'exercise_media.dart';
import 'exercise_media_picker.dart';
import 'exercise_media_picker_sheet.dart';
import 'exercise_media_thumbnail.dart';

Future<ExerciseBlock?> showExerciseBlockDialog(
  BuildContext context, {
  ExerciseBlock? existing,
}) {
  return showDialog<ExerciseBlock>(
    context: context,
    builder: (context) => ExerciseBlockDialog(existing: existing),
  );
}

class ExerciseBlockDialog extends StatefulWidget {
  const ExerciseBlockDialog({super.key, this.existing});

  final ExerciseBlock? existing;

  @override
  State<ExerciseBlockDialog> createState() => _ExerciseBlockDialogState();
}

class _MovementDraft {
  _MovementDraft({
    required this.title,
    required this.reps,
    required this.duration,
    required this.useDuration,
    this.previous,
  });

  factory _MovementDraft.from(ExercisePrescription? previous) {
    return _MovementDraft(
      title: TextEditingController(text: previous?.title ?? ''),
      reps: TextEditingController(text: '${previous?.prescribedReps ?? 12}'),
      duration: TextEditingController(
        text: '${previous?.prescribedDurationSeconds ?? 30}',
      ),
      useDuration: previous?.prescribedDurationSeconds != null,
      previous: previous,
    );
  }

  factory _MovementDraft.blank() => _MovementDraft.from(null);

  final TextEditingController title;
  final TextEditingController reps;
  final TextEditingController duration;
  bool useDuration;
  final ExercisePrescription? previous;

  void dispose() {
    title.dispose();
    reps.dispose();
    duration.dispose();
  }
}

class _ExerciseBlockDialogState extends State<ExerciseBlockDialog> {
  late final TextEditingController _sets;
  late final List<_MovementDraft> _movements;
  late bool _superset;
  String? _error;
  PickedExerciseMedia? _media;
  bool _mediaTouched = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final exercises = existing?.exercises ?? const <ExercisePrescription>[];
    _sets = TextEditingController(
      text: '${exercises.isEmpty ? 3 : exercises.first.prescribedSets}',
    );
    _superset = existing?.kind == BlockKind.superset;
    _media = existing == null
        ? null
        : PickedExerciseMedia.fromBlock(existing);
    _mediaTouched = _media != null;
    _movements = [
      if (exercises.isEmpty) _MovementDraft.blank() else ...[
        for (final exercise in exercises) _MovementDraft.from(exercise),
      ],
    ];
    if (_superset && _movements.length < 2) {
      _movements.add(_MovementDraft.blank());
    }
    for (final movement in _movements) {
      movement.title.addListener(_onTitleChanged);
    }
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    for (final movement in _movements) {
      movement.title.removeListener(_onTitleChanged);
    }
    _sets.dispose();
    for (final movement in _movements) {
      movement.dispose();
    }
    super.dispose();
  }

  int _parsePositive(String raw, int fallback) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 1) return fallback;
    return value;
  }

  String _titleLabel(int index) {
    if (index == 0) return 'exercise name';
    if (index == 1) return 'second exercise name';
    return 'exercise ${index + 1} name';
  }

  ExercisePrescription _prescription(_MovementDraft draft, int sets) {
    final title = draft.title.text.trim();
    return ExercisePrescription.create(
      prescriptionId: draft.previous?.prescriptionId ?? newId(),
      title: title,
      prescribedSets: sets,
      prescribedReps: draft.useDuration
          ? null
          : _parsePositive(draft.reps.text, 12),
      prescribedDurationSeconds: draft.useDuration
          ? _parsePositive(draft.duration.text, 30)
          : null,
    );
  }

  void _setSuperset(bool value) {
    setState(() {
      _superset = value;
      if (value && _movements.length < 2) {
        final draft = _MovementDraft.blank();
        draft.title.addListener(_onTitleChanged);
        _movements.add(draft);
      }
    });
  }

  void _addMovement() {
    setState(() {
      final draft = _MovementDraft.blank();
      draft.title.addListener(_onTitleChanged);
      _movements.add(draft);
    });
  }

  void _removeMovement(int index) {
    if (_movements.length <= 2) return;
    setState(() {
      final draft = _movements.removeAt(index);
      draft.title.removeListener(_onTitleChanged);
      draft.dispose();
    });
  }

  Future<void> _pickMedia() async {
    final picked = await showExerciseMediaPickerSheet(
      context,
      current: _media,
      titleHint: _movements.first.title.text,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _media = picked;
      _mediaTouched = true;
    });
  }

  void _clearMedia() {
    setState(() {
      _media = null;
      _mediaTouched = true;
    });
  }

  ExerciseBlock _buildBlock(int sets) {
    final block = ExerciseBlock.create(
      blockId: widget.existing?.blockId ?? newId(),
      kind: _superset ? BlockKind.superset : BlockKind.single,
      exercises: [
        for (final draft in (_superset ? _movements : _movements.take(1)))
          _prescription(draft, sets),
      ],
    );
    final media = _media;
    if (media != null) {
      media.applyTo(block);
    } else if (!_mediaTouched) {
      final match = bestAssetMatchForTitle(_movements.first.title.text);
      if (match != null) {
        PickedExerciseMedia.asset(match.assetPath).applyTo(block);
      }
    } else {
      PickedExerciseMedia.clearBlock(block);
    }
    return block;
  }

  void _submit() {
    final firstTitle = _movements.first.title.text.trim();
    if (firstTitle.isEmpty) {
      setState(() => _error = 'Add an exercise name');
      return;
    }
    if (_superset) {
      for (var i = 1; i < _movements.length; i++) {
        if (_movements[i].title.text.trim().isEmpty) {
          setState(() => _error = 'Add a name for each exercise in the superset');
          return;
        }
      }
    }
    final sets = _parsePositive(_sets.text, 3);
    Navigator.pop(context, _buildBlock(sets));
  }

  String _mediaLabel() {
    final media = _media;
    if (media == null) {
      final match = matchExerciseAsset(_movements.first.title.text);
      if (match != null && !_mediaTouched) {
        return 'Auto: ${match.label}';
      }
      return 'Auto from exercise name';
    }
    switch (media.source) {
      case ExerciseMediaSource.none:
        return 'Auto from exercise name';
      case ExerciseMediaSource.asset:
        final entry = bundledAssetByPath(media.uri);
        return entry?.label ?? 'Bundled asset';
      case ExerciseMediaSource.gallery:
        return media.kind == ExerciseMediaKind.video
            ? 'Gallery video'
            : 'Gallery photo';
      case ExerciseMediaSource.network:
        return 'Network link';
    }
  }

  ExerciseBlock _previewBlockData() {
    final preview = ExerciseBlock.create(
      blockId: 'preview',
      kind: BlockKind.single,
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'preview',
          title: _movements.first.title.text.trim().isEmpty
              ? 'Exercise'
              : _movements.first.title.text.trim(),
          prescribedSets: 1,
          prescribedReps: 12,
        ),
      ],
    );
    final media = _media;
    if (media != null) {
      media.applyTo(preview);
    }
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add exercise' : 'Edit exercise'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ListTile(
                key: const Key('exercise-media-picker'),
                contentPadding: EdgeInsets.zero,
                leading: ExerciseMediaThumbnail(
                  block: _previewBlockData(),
                  size: 48,
                ),
                title: const Text('Exercise preview'),
                subtitle: Text(_mediaLabel()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_media != null)
                      IconButton(
                        tooltip: 'Clear preview',
                        onPressed: _clearMedia,
                        icon: const Icon(Icons.close),
                      ),
                    IconButton(
                      tooltip: 'Choose preview',
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.image_outlined),
                    ),
                  ],
                ),
                onTap: _pickMedia,
              ),
              AppTextField(
                label: _titleLabel(0),
                controller: _movements.first.title,
                autofocus: true,
              ),
              _formDemo(_movements.first.title.text),
              AppTextField(
                label: 'sets',
                controller: _sets,
                keyboardType: TextInputType.number,
              ),
              _loadPicker(_movements.first),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Superset'),
                value: _superset,
                onChanged: _setSuperset,
              ),
              if (_superset) ...[
                for (var i = 1; i < _movements.length; i++)
                  _extraMovement(context, i),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('add-movement'),
                    onPressed: _addMovement,
                    icon: const Icon(Icons.add),
                    label: const Text('Add movement'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save exercise'),
        ),
      ],
    );
  }

  Widget _formDemo(String title) {
    final match = matchExerciseAsset(title);
    if (match == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        children: [
          Image.asset(
            match.gifPath,
            key: Key('exercise-form-gif-${match.id}'),
            width: 120,
            height: 120,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
          Text(
            'How to: ${match.label}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _extraMovement(BuildContext context, int index) {
    final draft = _movements[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: _titleLabel(index),
                  controller: draft.title,
                ),
              ),
              if (_movements.length > 2)
                IconButton(
                  tooltip: 'Remove movement',
                  onPressed: () => _removeMovement(index),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
          _loadPicker(draft),
        ],
      ),
    );
  }

  Widget _loadPicker(_MovementDraft draft) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Reps'),
              selected: !draft.useDuration,
              onSelected: (_) => setState(() => draft.useDuration = false),
            ),
            ChoiceChip(
              label: const Text('Duration'),
              selected: draft.useDuration,
              onSelected: (_) => setState(() => draft.useDuration = true),
            ),
          ],
        ),
        if (draft.useDuration)
          AppTextField(
            label: 'seconds',
            controller: draft.duration,
            keyboardType: TextInputType.number,
          )
        else
          AppTextField(
            label: 'reps',
            controller: draft.reps,
            keyboardType: TextInputType.number,
          ),
      ],
    );
  }
}
