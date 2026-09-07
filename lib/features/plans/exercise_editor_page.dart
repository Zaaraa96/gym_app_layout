import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../common/exercise_asset_catalog.dart';
import '../../common/widgets/app_text_field.dart';
import '../../domain/exercise_editor_draft.dart';
import '../../domain/models/models.dart';
import '../../domain/new_id.dart';
import '../../domain/plan_catalog.dart';
import 'exercise_media_picker.dart';
import 'exercise_media_picker_sheet.dart';
import 'exercise_media_thumbnail.dart';
import 'target_area_chips.dart';

sealed class ExerciseEditorResult {
  const ExerciseEditorResult();
}

class ExerciseEditorSaved extends ExerciseEditorResult {
  const ExerciseEditorSaved(this.block);

  final ExerciseBlock block;
}

class ExerciseEditorDeleted extends ExerciseEditorResult {
  const ExerciseEditorDeleted();
}

/// Opens the full-screen exercise editor over the current route.
///
/// [onSave] and [onDelete] run before the modal closes. Return `false` to keep
/// the editor open (for example when the parent draft failed to persist).
Future<ExerciseEditorResult?> showExerciseEditor(
  BuildContext context, {
  ExerciseBlock? existing,
  List<String> goalIds = const [],
  String dayLabel = '',
  Future<bool> Function(ExerciseBlock block)? onSave,
  Future<bool> Function()? onDelete,
}) {
  return Navigator.of(context, rootNavigator: true).push<ExerciseEditorResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ExerciseEditorPage(
        existing: existing,
        goalIds: goalIds,
        dayLabel: dayLabel,
        onSave: onSave,
        onDelete: onDelete,
      ),
    ),
  );
}

/// Compatibility wrapper used by older call sites and tests.
Future<ExerciseEditorResult?> showExerciseBlockDialog(
  BuildContext context, {
  ExerciseBlock? existing,
  List<String> goalIds = const [],
  String dayLabel = '',
  Future<bool> Function(ExerciseBlock block)? onSave,
  Future<bool> Function()? onDelete,
}) {
  return showExerciseEditor(
    context,
    existing: existing,
    goalIds: goalIds,
    dayLabel: dayLabel,
    onSave: onSave,
    onDelete: onDelete,
  );
}

class ExerciseEditorPage extends StatefulWidget {
  const ExerciseEditorPage({
    super.key,
    this.existing,
    this.goalIds = const [],
    this.dayLabel = '',
    this.onSave,
    this.onDelete,
  });

  final ExerciseBlock? existing;
  final List<String> goalIds;
  final String dayLabel;
  final Future<bool> Function(ExerciseBlock block)? onSave;
  final Future<bool> Function()? onDelete;

  @override
  State<ExerciseEditorPage> createState() => _ExerciseEditorPageState();
}

class _MovementFields {
  _MovementFields({
    required this.title,
    required this.reps,
    required this.duration,
    required this.titleFocus,
  });

  factory _MovementFields.from(ExerciseMovementDraft movement) {
    return _MovementFields(
      title: TextEditingController(text: movement.title),
      reps: TextEditingController(text: '${movement.reps ?? 12}'),
      duration: TextEditingController(text: '${movement.durationSeconds ?? 30}'),
      titleFocus: FocusNode(),
    );
  }

  final TextEditingController title;
  final TextEditingController reps;
  final TextEditingController duration;
  final FocusNode titleFocus;

  void dispose() {
    title.dispose();
    reps.dispose();
    duration.dispose();
    titleFocus.dispose();
  }
}

class _ExerciseEditorPageState extends State<ExerciseEditorPage> {
  late final ExerciseBlockDraft _draft;
  late final List<_MovementFields> _fields;
  late final TextEditingController _sets;
  late final TextEditingController _rounds;
  late final FocusNode _roundsFocus;
  var _showErrors = false;
  String? _banner;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _draft = existing == null
        ? ExerciseBlockDraft.createNew()
        : ExerciseBlockDraft.fromBlock(existing);
    _fields = [
      for (final movement in _draft.movements) _MovementFields.from(movement),
    ];
    _sets = TextEditingController(text: '${_draft.movements.first.sets ?? 3}');
    _rounds = TextEditingController(
      text: _draft.unequalRounds ? '' : '${_draft.rounds ?? 3}',
    );
    _roundsFocus = FocusNode();
  }

  @override
  void dispose() {
    for (final fields in _fields) {
      fields.dispose();
    }
    _sets.dispose();
    _rounds.dispose();
    _roundsFocus.dispose();
    super.dispose();
  }

  void _syncDraftFromFields() {
    for (var i = 0; i < _draft.movements.length && i < _fields.length; i++) {
      final movement = _draft.movements[i];
      final fields = _fields[i];
      movement.title = fields.title.text;
      movement.reps = int.tryParse(fields.reps.text.trim());
      movement.durationSeconds = int.tryParse(fields.duration.text.trim());
    }
    if (_draft.isSuperset) {
      final rounds = int.tryParse(_rounds.text.trim());
      _draft.rounds = rounds;
      if (rounds != null && rounds >= 1) _draft.unequalRounds = false;
    } else {
      _draft.movements.first.sets = int.tryParse(_sets.text.trim());
    }
  }

  Future<void> _onTitleChanged(int index, String value) async {
    _draft.movements[index].setTitle(value);
    _draft.markDirty();
    setState(() {});
  }

  Future<bool> _confirmCatalogReplace(ExerciseAssetEntry entry) async {
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace target areas?'),
        content: const Text(
          'This name matches a catalog exercise. Replace your target '
          'areas with the catalog defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep mine'),
          ),
          FilledButton(
            key: const Key('replace-target-areas'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use catalog'),
          ),
        ],
      ),
    );
    return replace == true;
  }

  Future<void> _selectCatalog(int index, ExerciseAssetEntry entry) async {
    final movement = _draft.movements[index];
    if (movement.catalogWouldReplaceManual(entry)) {
      final replace = await _confirmCatalogReplace(entry);
      if (!mounted) return;
      if (!replace) {
        movement.title = entry.label;
        movement.catalogExerciseId = entry.id;
        _fields[index].title.text = entry.label;
        _draft.markDirty();
        setState(() {});
        return;
      }
      movement.applyCatalog(entry, replaceManual: true);
    } else {
      movement.applyCatalog(entry);
    }
    _fields[index].title.text = entry.label;
    _draft.markDirty();
    setState(() {});
  }

  Future<void> _setMode(ExerciseEditorMode mode) async {
    if (mode == _draft.mode) return;
    if (mode == ExerciseEditorMode.superset) {
      _draft.switchToSuperset();
      _rounds.text = '${_draft.rounds ?? 3}';
      while (_fields.length < _draft.movements.length) {
        _fields.add(_MovementFields.from(_draft.movements[_fields.length]));
      }
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_fields.length > 1) _fields[1].titleFocus.requestFocus();
      });
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Superset mode',
        TextDirection.ltr,
      );
      return;
    }
    if (!_draft.switchToSingle()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch to a single exercise?'),
          content: const Text(
            'Movement B and any additional movements will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-switch-single'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Switch and remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      _draft.switchToSingle(confirmed: true);
    }
    _sets.text = '${_draft.movements.first.sets ?? 3}';
    while (_fields.length > 1) {
      _fields.removeLast().dispose();
    }
    setState(() {});
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Single exercise mode',
      TextDirection.ltr,
    );
  }

  void _addMovement() {
    _draft.addMovement();
    _fields.add(_MovementFields.from(_draft.movements.last));
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fields.last.titleFocus.requestFocus();
    });
  }

  void _removeMovement(int index) {
    if (!_draft.removeMovement(index)) {
      setState(() {
        _banner = 'A superset needs at least 2 exercises.';
      });
      SemanticsService.sendAnnouncement(
        View.of(context),
        'A superset needs at least 2 exercises.',
        TextDirection.ltr,
      );
      return;
    }
    _fields.removeAt(index).dispose();
    setState(() => _banner = null);
  }

  void _reorder(int oldIndex, int newIndex) {
    _draft.reorderMovements(oldIndex, newIndex);
    final item = _fields.removeAt(oldIndex);
    _fields.insert(newIndex, item);
    setState(() {});
  }

  Future<void> _pickMedia(int index) async {
    final movement = _draft.movements[index];
    final current = movement.media == null
        ? null
        : PickedExerciseMedia(
            uri: movement.media!.uri,
            source: movement.media!.source,
            kind: movement.media!.kind,
          );
    final picked = await showExerciseMediaPickerSheet(
      context,
      current: current,
      titleHint: movement.title,
    );
    if (!mounted || picked == null) return;
    setState(() {
      movement.media = ExerciseMediaDraft(
        uri: picked.uri,
        source: picked.source,
        kind: picked.kind,
        userEdited: true,
      );
      movement.manualMedia = true;
      _draft.markDirty();
    });
  }

  void _clearMedia(int index) {
    setState(() {
      _draft.movements[index].media = null;
      _draft.movements[index].manualMedia = true;
      _draft.markDirty();
    });
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard exercise changes?'),
        content: const Text(
          'Changes made in this editor have not been added to the day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('discard-exercise-changes'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _close() async {
    if (!_draft.dirty) {
      Navigator.pop(context);
      return;
    }
    if (await _confirmDiscard() && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    _syncDraftFromFields();
    for (var i = 0; i < _draft.movements.length; i++) {
      final movement = _draft.movements[i];
      if (!_draft.isSuperset && i > 0) break;
      final match = matchExerciseAsset(movement.title);
      if (match == null) continue;
      if (movement.catalogWouldReplaceManual(match)) {
        final replace = await _confirmCatalogReplace(match);
        if (!mounted) return;
        if (replace) movement.applyCatalog(match, replaceManual: true);
      } else if (movement.catalogExerciseId != match.id) {
        movement.applyCatalog(match);
      }
    }
    final issues = _draft.validate();
    if (issues.isNotEmpty) {
      setState(() {
        _showErrors = true;
        _banner = issues.first.message;
      });
      SemanticsService.sendAnnouncement(
        View.of(context),
        issues.first.message,
        TextDirection.ltr,
      );
      final index = issues.first.movementIndex ?? 0;
      if (index >= 0 && index < _fields.length) {
        _fields[index].titleFocus.requestFocus();
      } else if (_draft.isSuperset) {
        _roundsFocus.requestFocus();
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final block = _draft.toBlock(newId: newId);
      final persist = widget.onSave;
      final ok = persist == null ? true : await persist(block);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _saving = false;
          _banner = 'Could not save exercise. Try again.';
        });
        return;
      }
      Navigator.pop(context, ExerciseEditorSaved(block));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _banner = 'Could not save exercise. Try again.';
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_draft.deleteActionLabel),
        content: Text(
          _draft.isSuperset
              ? 'Remove this superset from the day?'
              : 'Remove this exercise from the day?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-exercise'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final persist = widget.onDelete;
    final ok = persist == null ? true : await persist();
    if (!mounted) return;
    if (!ok) {
      setState(() => _banner = 'Could not save exercise. Try again.');
      return;
    }
    Navigator.pop(context, const ExerciseEditorDeleted());
  }

  String _titleLabel(int index) {
    if (index == 0) return 'exercise name';
    if (index == 1) return 'second exercise name';
    return 'exercise ${index + 1} name';
  }

  ExerciseBlock _previewBlock(ExerciseMovementDraft movement) {
    return ExerciseBlock.create(
      blockId: 'preview',
      kind: BlockKind.single,
      exercises: [
        ExercisePrescription.create(
          prescriptionId: 'preview',
          title: movement.title.trim().isEmpty ? 'Exercise' : movement.title,
          prescribedSets: 1,
          prescribedReps: 12,
          svgPath: movement.media?.source == ExerciseMediaSource.asset
              ? movement.media?.uri
              : null,
          mediaUri: movement.media?.uri,
          mediaSource: movement.media?.source ?? ExerciseMediaSource.none,
          mediaKind: movement.media?.kind ?? ExerciseMediaKind.unknown,
        ),
      ],
    );
  }

  String _mediaCaption(ExerciseMovementDraft movement) {
    final media = movement.media;
    if (media == null) return 'Optional';
    if (media.catalogSuggested && !media.userEdited) return 'Suggested image';
    switch (media.source) {
      case ExerciseMediaSource.asset:
        return bundledAssetByPath(media.uri)?.label ?? 'Bundled asset';
      case ExerciseMediaSource.gallery:
        return media.kind == ExerciseMediaKind.video
            ? 'Gallery video'
            : 'Gallery photo';
      case ExerciseMediaSource.network:
        return 'Network link';
      case ExerciseMediaSource.none:
        return 'Optional';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issues = _showErrors ? _draft.validate() : const <ExerciseEditorIssue>[];
    return PopScope(
      canPop: !_draft.dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _close();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Close exercise editor',
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_draft.appBarTitle),
              if (widget.dayLabel.isNotEmpty)
                Text(
                  widget.dayLabel,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_banner != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _banner!,
                  style: TextStyle(
                    color: _banner!.startsWith('This superset')
                        ? Colors.amber.shade800
                        : theme.colorScheme.error,
                  ),
                ),
              ),
            Text('Exercise type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ExerciseEditorMode>(
              segments: const [
                ButtonSegment(
                  value: ExerciseEditorMode.single,
                  label: Text('Single exercise'),
                  icon: Icon(Icons.fitness_center),
                ),
                ButtonSegment(
                  value: ExerciseEditorMode.superset,
                  label: Text('Superset'),
                  icon: Icon(Icons.link),
                ),
              ],
              selected: {_draft.mode},
              onSelectionChanged: (value) => _setMode(value.first),
            ),
            const SizedBox(height: 16),
            if (_draft.isSuperset) ...[
              if (_draft.unequalRounds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'This superset has different set counts. Choose rounds '
                    'to apply to every movement.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              _CountStepper(
                label: 'Rounds',
                helper: 'Applies to the entire superset.',
                controller: _rounds,
                fieldKey: const Key('exercise-rounds'),
                focusNode: _roundsFocus,
                decreaseLabel: 'Decrease rounds',
                increaseLabel: 'Increase rounds',
                onChanged: (value) {
                  _draft.setRounds(value);
                  _rounds.text = '$value';
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _draft.movements.length,
                onReorderItem: _reorder,
                itemBuilder: (context, index) => KeyedSubtree(
                  key: ValueKey('movement-$index-${_draft.movements[index].prescriptionId}'),
                  child: _movementCard(context, index, issues),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('add-movement'),
                onPressed: _addMovement,
                icon: const Icon(Icons.add),
                label: const Text('Add another exercise'),
              ),
              const SizedBox(height: 4),
              Text(
                'A superset needs at least 2 exercises.',
                style: theme.textTheme.bodySmall,
              ),
            ] else
              _movementCard(context, 0, issues, showSets: true),
            if (!_draft.isNew) ...[
              const SizedBox(height: 24),
              TextButton(
                key: const Key('delete-exercise'),
                onPressed: _delete,
                child: Text(_draft.deleteActionLabel),
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              key: const Key('exercise-editor-commit'),
              onPressed: _saving ? null : _submit,
              child: Text(_draft.primaryActionLabel),
            ),
          ),
        ),
      ),
    );
  }

  Widget _movementCard(
    BuildContext context,
    int index,
    List<ExerciseEditorIssue> issues, {
    bool showSets = false,
  }) {
    final theme = Theme.of(context);
    final movement = _draft.movements[index];
    final fields = _fields[index];
    final query = fields.title.text;
    final results = searchExerciseCatalog(
      query: query,
      goalIds: widget.goalIds,
    );
    final selected = () {
      if (movement.catalogExerciseId != null) {
        for (final entry in bundledExerciseAssets) {
          if (entry.id == movement.catalogExerciseId) return entry;
        }
      }
      return matchExerciseAsset(movement.title);
    }();
    final fieldError = issues
        .where((issue) => issue.movementIndex == index)
        .map((issue) => issue.message)
        .join('\n');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_draft.isSuperset)
              Row(
                children: [
                  const Icon(Icons.drag_handle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      movementLabel(index),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove ${movementLabel(index)}',
                    onPressed: () => _removeMovement(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            AppTextField(
              key: Key('exercise-name-$index'),
              label: _titleLabel(index),
              controller: fields.title,
              focusNode: fields.titleFocus,
              autofocus: index == 0 && _draft.isNew,
              onChanged: (value) => _onTitleChanged(index, value),
            ),
            if (fieldError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  fieldError,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (selected != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.asset(
                  selected.assetPath,
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center),
                ),
                title: Text(selected.label),
                subtitle: Text(
                  selected.targetAreaIds
                      .map(targetAreaLabel)
                      .join(' · '),
                ),
                trailing: const Icon(Icons.check_circle),
              )
            else if (query.trim().isEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in results)
                    ActionChip(
                      key: Key('suggest-${entry.id}'),
                      label: Text(entry.label),
                      onPressed: () => _selectCatalog(index, entry),
                    ),
                ],
              )
            else
              Column(
                children: [
                  for (final entry in results)
                    ListTile(
                      key: Key('suggest-${entry.id}'),
                      leading: Image.asset(
                        entry.assetPath,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fitness_center),
                      ),
                      title: Text(entry.label),
                      onTap: () => _selectCatalog(index, entry),
                    ),
                ],
              ),
            TargetAreaChips(
              selectedIds: movement.targetAreaIds,
              catalogSuggested: movement.hasCatalogTargets,
              onChanged: (ids) {
                setState(() {
                  movement.targetAreaIds = ids;
                  movement.manualTargets = true;
                  _draft.markDirty();
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Prescription', style: theme.textTheme.titleSmall),
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
              selected: {movement.type},
              onSelectionChanged: (value) {
                setState(() {
                  movement.type = value.first;
                  _draft.markDirty();
                });
              },
            ),
            const SizedBox(height: 8),
            if (showSets)
              _CountStepper(
                label: 'Sets',
                controller: _sets,
                fieldKey: const Key('exercise-sets'),
                decreaseLabel: 'Decrease sets',
                increaseLabel: 'Increase sets',
                onChanged: (value) {
                  movement.sets = value;
                  _sets.text = '$value';
                  _draft.markDirty();
                  setState(() {});
                },
              ),
            if (movement.type == PrescriptionType.reps)
              _CountStepper(
                label: showSets ? 'Reps per set' : 'Reps',
                controller: fields.reps,
                fieldKey: Key('exercise-reps-$index'),
                decreaseLabel: 'Decrease reps',
                increaseLabel: 'Increase reps',
                onChanged: (value) {
                  movement.reps = value;
                  fields.reps.text = '$value';
                  _draft.markDirty();
                  setState(() {});
                },
              )
            else
              _CountStepper(
                label: 'Duration (seconds)',
                controller: fields.duration,
                fieldKey: Key('exercise-duration-$index'),
                decreaseLabel: 'Decrease duration',
                increaseLabel: 'Increase duration',
                onChanged: (value) {
                  movement.durationSeconds = value;
                  fields.duration.text = '$value';
                  _draft.markDirty();
                  setState(() {});
                },
              ),
            const SizedBox(height: 8),
            Text('Exercise image', style: theme.textTheme.titleSmall),
            Text('Optional', style: theme.textTheme.bodySmall),
            ListTile(
              key: index == 0
                  ? const Key('exercise-media-picker')
                  : Key('exercise-media-picker-$index'),
              contentPadding: EdgeInsets.zero,
              leading: ExerciseMediaThumbnail(
                block: _previewBlock(movement),
                size: 48,
              ),
              title: Text(_mediaCaption(movement)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (movement.media != null)
                    IconButton(
                      tooltip: 'Remove image',
                      onPressed: () => _clearMedia(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  IconButton(
                    tooltip: 'Change image',
                    onPressed: () => _pickMedia(index),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              onTap: () => _pickMedia(index),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.helper,
    this.focusNode,
  });

  final String label;
  final String? helper;
  final TextEditingController controller;
  final Key fieldKey;
  final ValueChanged<int> onChanged;
  final String decreaseLabel;
  final String increaseLabel;
  final FocusNode? focusNode;

  int get _value {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                if (helper != null)
                  Text(helper!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: decreaseLabel,
            onPressed: () => onChanged(_value <= 1 ? 1 : _value - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 64,
            child: TextFormField(
              key: fieldKey,
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (raw) {
                final value = int.tryParse(raw.trim());
                if (value != null && value >= 1) onChanged(value);
              },
            ),
          ),
          IconButton(
            tooltip: increaseLabel,
            onPressed: () => onChanged(_value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
