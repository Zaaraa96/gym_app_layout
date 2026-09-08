import 'package:flutter/material.dart';

import '../../common/widgets/app_text.dart';
import '../../common/widgets/app_text_field.dart';
import '../../domain/models/models.dart';
import 'block_summary.dart';
import 'exercise_media_thumbnail.dart';
import 'remove_exercise.dart';
import 'target_area_chips.dart';

/// Day name, blocks, and add-exercise used by Create plan and Edit day.
class DayStepBody extends StatelessWidget {
  const DayStepBody({
    super.key,
    required this.day,
    required this.title,
    required this.summary,
    required this.onTitleChanged,
    required this.onSummaryChanged,
    required this.onAddExercise,
    required this.onEditBlock,
    required this.onDeleteBlock,
    this.onMoveUp,
    this.onMoveDown,
    this.addExerciseKey,
    this.continueKey,
    this.onContinue,
    this.continueEnabled = true,
    this.continueLabel = 'CONTINUE',
    this.onDeleteDay,
  });

  final PlanDay day;
  final TextEditingController title;
  final TextEditingController summary;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSummaryChanged;
  final VoidCallback onAddExercise;
  final void Function(int index) onEditBlock;
  final Future<void> Function(int index) onDeleteBlock;
  final void Function(int index)? onMoveUp;
  final void Function(int index)? onMoveDown;
  final Key? addExerciseKey;
  final Key? continueKey;
  final VoidCallback? onContinue;
  final bool continueEnabled;
  final String continueLabel;
  final VoidCallback? onDeleteDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Day name',
          controller: title,
          onChanged: onTitleChanged,
        ),
        AppTextField(
          label: 'Summary (optional)',
          controller: summary,
          maxLines: 2,
          onChanged: onSummaryChanged,
        ),
        if (day.blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: AppText(
              'Add at least one exercise.',
              style: subtitleTextStyle,
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < day.blocks.length; index++)
                DayBlockCard(
                  key: Key('builder-block-${day.blocks[index].blockId}'),
                  block: day.blocks[index],
                  onEdit: () => onEditBlock(index),
                  onDelete: () async {
                    final block = day.blocks[index];
                    final confirmed = await confirmRemoveExerciseFromDay(
                      context,
                      isSuperset: block.kind == BlockKind.superset,
                    );
                    if (!confirmed) return;
                    await onDeleteBlock(index);
                  },
                  onMoveUp: index == 0 || onMoveUp == null
                      ? null
                      : () => onMoveUp!(index),
                  onMoveDown: index == day.blocks.length - 1 ||
                          onMoveDown == null
                      ? null
                      : () => onMoveDown!(index),
                ),
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: addExerciseKey ?? Key('add-exercise-${day.dayId}'),
          onPressed: onAddExercise,
          icon: const Icon(Icons.add),
          label: const Text('Add exercise'),
        ),
        if (onDeleteDay != null)
          TextButton(
            onPressed: onDeleteDay,
            child: const Text('Delete day'),
          ),
        if (onContinue != null) ...[
          const SizedBox(height: 8),
          FilledButton(
            key: continueKey ?? Key('continue-day-${day.dayId}'),
            onPressed: continueEnabled ? onContinue : null,
            child: Text(continueLabel),
          ),
        ],
      ],
    );
  }
}

class DayBlockCard extends StatelessWidget {
  const DayBlockCard({
    super.key,
    required this.block,
    required this.onEdit,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ExerciseBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuperset = block.kind == BlockKind.superset;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isSuperset
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (isSuperset)
                  Expanded(
                    child: Text(
                      'SUPERSET',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                IconButton(
                  tooltip: isSuperset ? 'Edit superset' : 'Edit exercise',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: isSuperset ? 'Delete superset' : 'Delete exercise',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
            for (var i = 0; i < block.exercises.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ExerciseMediaThumbnail(
                  block: ExerciseBlock.create(
                    blockId: block.blockId,
                    kind: BlockKind.single,
                    svgPath: i == 0 ? block.svgPath : null,
                    mediaUri: i == 0 ? block.mediaUri : null,
                    mediaSource: i == 0
                        ? block.mediaSource
                        : ExerciseMediaSource.none,
                    mediaKind: i == 0
                        ? block.mediaKind
                        : ExerciseMediaKind.unknown,
                    exercises: [block.exercises[i]],
                  ),
                  size: 48,
                ),
                title: Text(block.exercises[i].title),
                subtitle: Text(formatLoad(block.exercises[i])),
                onTap: onEdit,
              ),
              TargetAreaChips(
                selectedIds: block.exercises[i].targetAreaIds,
                readOnly: true,
                onChanged: (_) => onEdit(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
