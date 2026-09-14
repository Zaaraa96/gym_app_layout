import 'package:flutter/material.dart';

import '../../common/widgets/app_text.dart';
import '../../domain/models/schedule.dart';
import '../../domain/plan_progress.dart';

/// Plan-scoped progress + simple charts for Plan preview.
class PlanProgressSection extends StatelessWidget {
  const PlanProgressSection({
    super.key,
    required this.progress,
    this.onRunAgain,
  });

  final PlanProgress progress;
  final VoidCallback? onRunAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('plan-progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppText('Progress', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          progress.mode == ScheduleMode.once
              ? progress.onceHeadline
              : progress.weekHeadline,
          style: theme.textTheme.titleSmall,
        ),
        if (progress.isFinishedOnce) ...[
          const SizedBox(height: 4),
          Text(
            'This Run once plan is finished and off the schedule.',
            style: theme.textTheme.bodySmall,
          ),
          if (onRunAgain != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('run-once-again'),
              onPressed: onRunAgain,
              child: const Text('Run again'),
            ),
          ],
        ],
        if (progress.lastTrainedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Last trained ${_formatDate(progress.lastTrainedAt!)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (progress.mode == ScheduleMode.week) ...[
          const SizedBox(height: 12),
          _weekStrip(context),
        ],
        if (progress.mode == ScheduleMode.once) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in progress.dayStates.entries)
                Chip(
                  label: Text(
                    '${_stateWord(entry.value)} · ${progress.dayTitles[entry.key] ?? entry.key}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
        if (progress.weightTrend.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Weight over sessions', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: _MiniBars(
              points: progress.weightTrend,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
        if (progress.weeklySessionCounts.any((p) => p.value > 0)) ...[
          const SizedBox(height: 16),
          Text('Sessions per week', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: _MiniBars(
              points: progress.weeklySessionCounts,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _weekStrip(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final cell in progress.weekStrip)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _markColor(theme, cell.mark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    weekdayLabels[cell.weekday]!,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _markLabel(cell),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _markColor(ThemeData theme, WeekStripMark mark) {
    switch (mark) {
      case WeekStripMark.trained:
        return theme.colorScheme.primaryContainer;
      case WeekStripMark.skipped:
        return theme.colorScheme.errorContainer;
      case WeekStripMark.due:
        return theme.colorScheme.secondaryContainer;
      case WeekStripMark.rest:
        return theme.colorScheme.surfaceContainerHighest;
      case WeekStripMark.upcoming:
        return theme.colorScheme.surfaceContainerHigh;
    }
  }

  String _markLabel(WeekStripCell cell) {
    switch (cell.mark) {
      case WeekStripMark.rest:
        return 'Rest';
      case WeekStripMark.trained:
        return 'Trained';
      case WeekStripMark.skipped:
        return 'Skipped';
      case WeekStripMark.due:
        return cell.dayTitle ?? 'Due';
      case WeekStripMark.upcoming:
        return cell.dayTitle ?? 'Soon';
    }
  }

  String _stateWord(PlanDayProgressState state) => switch (state) {
        PlanDayProgressState.done => 'Done',
        PlanDayProgressState.skipped => 'Skipped',
        PlanDayProgressState.left => 'Left',
      };

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.points, required this.color});

  final List<PlanChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final max = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final point in points)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: max <= 0 ? 0 : (point.value / max).clamp(0.05, 1),
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
