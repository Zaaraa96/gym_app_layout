import 'package:flutter/material.dart';

import '../../domain/plan_catalog.dart';

/// Editable target-area chips. Ownership stays on the exercise, not the block.
class TargetAreaChips extends StatelessWidget {
  const TargetAreaChips({
    super.key,
    required this.selectedIds,
    this.onChanged,
    this.readOnly = false,
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final selected = canonicalizeTargetAreaIds(selectedIds);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target areas',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          if (selected.isEmpty && readOnly)
            Text(
              'No target areas',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in selected)
                  InputChip(
                    key: Key('target-$id'),
                    label: Text(targetAreaLabel(id)),
                    onDeleted: readOnly || onChanged == null
                        ? null
                        : () {
                            onChanged!([
                              for (final item in selected)
                                if (item != id) item,
                            ]);
                          },
                    deleteButtonTooltipMessage: 'Remove ${targetAreaLabel(id)}',
                  ),
                if (!readOnly && onChanged != null)
                  _AddTargetAreaButton(
                    selectedIds: selected,
                    onChanged: onChanged!,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AddTargetAreaButton extends StatelessWidget {
  const _AddTargetAreaButton({
    required this.selectedIds,
    required this.onChanged,
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final remaining = [
      for (final area in targetAreas)
        if (!selectedIds.contains(area.id)) area,
    ];
    if (remaining.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      key: const Key('add-target-area'),
      tooltip: 'Add target area',
      onSelected: (id) => onChanged([...selectedIds, id]),
      itemBuilder: (context) => [
        for (final area in remaining)
          PopupMenuItem(
            value: area.id,
            child: Text(area.label),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: const Chip(
            avatar: Icon(Icons.add, size: 18),
            label: Text('Add target area'),
          ),
        ),
      ),
    );
  }
}
