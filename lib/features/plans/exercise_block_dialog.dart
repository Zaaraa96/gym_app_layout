import 'package:flutter/material.dart';

import '../../common/widgets/app_text_field.dart';
import '../../data/models/models.dart';
import '../../data/new_id.dart';

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

class _ExerciseBlockDialogState extends State<ExerciseBlockDialog> {
  late final TextEditingController _title;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _duration;
  late final TextEditingController _secondTitle;
  late final TextEditingController _secondReps;
  late final TextEditingController _secondDuration;
  late bool _useDuration;
  late bool _superset;
  late bool _secondUseDuration;
  String? _error;

  ExercisePrescription? get _first {
    final exercises = widget.existing?.exercises;
    if (exercises == null || exercises.isEmpty) return null;
    return exercises.first;
  }

  ExercisePrescription? get _second {
    final exercises = widget.existing?.exercises;
    if (exercises == null || exercises.length < 2) return null;
    return exercises[1];
  }

  @override
  void initState() {
    super.initState();
    final first = _first;
    final second = _second;
    _title = TextEditingController(text: first?.title ?? '');
    _sets = TextEditingController(text: '${first?.prescribedSets ?? 3}');
    _useDuration = first?.prescribedDurationSeconds != null;
    _reps = TextEditingController(text: '${first?.prescribedReps ?? 12}');
    _duration = TextEditingController(
      text: '${first?.prescribedDurationSeconds ?? 30}',
    );
    _superset = widget.existing?.kind == BlockKind.superset;
    _secondTitle = TextEditingController(text: second?.title ?? '');
    _secondUseDuration = second?.prescribedDurationSeconds != null;
    _secondReps = TextEditingController(text: '${second?.prescribedReps ?? 12}');
    _secondDuration = TextEditingController(
      text: '${second?.prescribedDurationSeconds ?? 30}',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _sets.dispose();
    _reps.dispose();
    _duration.dispose();
    _secondTitle.dispose();
    _secondReps.dispose();
    _secondDuration.dispose();
    super.dispose();
  }

  int _parsePositive(String raw, int fallback) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 1) return fallback;
    return value;
  }

  ExercisePrescription _prescription({
    required String title,
    required int sets,
    required bool useDuration,
    required String repsText,
    required String durationText,
    ExercisePrescription? previous,
  }) {
    return ExercisePrescription.create(
      prescriptionId: previous?.prescriptionId ?? newId(),
      title: title,
      prescribedSets: sets,
      prescribedReps: useDuration ? null : _parsePositive(repsText, 12),
      prescribedDurationSeconds:
          useDuration ? _parsePositive(durationText, 30) : null,
    );
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Add an exercise name');
      return;
    }
    if (_superset && _secondTitle.text.trim().isEmpty) {
      setState(() => _error = 'Add a name for the second exercise');
      return;
    }
    final sets = _parsePositive(_sets.text, 3);
    final exercises = [
      _prescription(
        title: title,
        sets: sets,
        useDuration: _useDuration,
        repsText: _reps.text,
        durationText: _duration.text,
        previous: _first,
      ),
      if (_superset)
        _prescription(
          title: _secondTitle.text.trim(),
          sets: sets,
          useDuration: _secondUseDuration,
          repsText: _secondReps.text,
          durationText: _secondDuration.text,
          previous: _second,
        ),
    ];
    Navigator.pop(
      context,
      ExerciseBlock.create(
        blockId: widget.existing?.blockId ?? newId(),
        kind: _superset ? BlockKind.superset : BlockKind.single,
        svgPath: widget.existing?.svgPath,
        exercises: exercises,
      ),
    );
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
              AppTextField(
                label: 'exercise name',
                controller: _title,
                autofocus: true,
              ),
              AppTextField(
                label: 'sets',
                controller: _sets,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Reps'),
                    selected: !_useDuration,
                    onSelected: (_) => setState(() => _useDuration = false),
                  ),
                  ChoiceChip(
                    label: const Text('Duration'),
                    selected: _useDuration,
                    onSelected: (_) => setState(() => _useDuration = true),
                  ),
                ],
              ),
              if (_useDuration)
                AppTextField(
                  label: 'seconds',
                  controller: _duration,
                  keyboardType: TextInputType.number,
                )
              else
                AppTextField(
                  label: 'reps',
                  controller: _reps,
                  keyboardType: TextInputType.number,
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Superset'),
                value: _superset,
                onChanged: (value) => setState(() => _superset = value),
              ),
              if (_superset) ...[
                AppTextField(
                  label: 'second exercise name',
                  controller: _secondTitle,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Reps'),
                      selected: !_secondUseDuration,
                      onSelected: (_) =>
                          setState(() => _secondUseDuration = false),
                    ),
                    ChoiceChip(
                      label: const Text('Duration'),
                      selected: _secondUseDuration,
                      onSelected: (_) =>
                          setState(() => _secondUseDuration = true),
                    ),
                  ],
                ),
                if (_secondUseDuration)
                  AppTextField(
                    label: 'seconds',
                    controller: _secondDuration,
                    keyboardType: TextInputType.number,
                  )
                else
                  AppTextField(
                    label: 'reps',
                    controller: _secondReps,
                    keyboardType: TextInputType.number,
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
}
