import 'package:flutter/material.dart';

import '../../common/widgets/app_text.dart';
import '../../domain/models/models.dart';

/// Shared On schedule / once|week / weekday map controls for Review and Plan preview.
class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({
    super.key,
    required this.plan,
    required this.onChanged,
    this.showTitle = true,
  });

  final WorkoutPlan plan;
  final VoidCallback onChanged;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    ensurePlanScheduleDefaults(plan);
    final theme = Theme.of(context);
    final unassigned = unassignedWorkoutDays(plan);
    return Column(
      key: const Key('schedule-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          const AppText('Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Only on-schedule plans appear in Today. Week schedule maps days to weekdays; empty weekdays are Rest.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
        ],
        SwitchListTile(
          key: const Key('on-schedule-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('On schedule'),
          subtitle: const Text('Show this plan in Today when active'),
          value: plan.onSchedule,
          onChanged: (value) {
            plan.onSchedule = value;
            onChanged();
          },
        ),
        const SizedBox(height: 4),
        Text('How you follow this plan', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ScheduleMode>(
          key: const Key('schedule-mode'),
          segments: const [
            ButtonSegment(
              value: ScheduleMode.once,
              label: Text('Run once'),
              icon: Icon(Icons.looks_one_outlined),
            ),
            ButtonSegment(
              value: ScheduleMode.week,
              label: Text('Week schedule'),
              icon: Icon(Icons.date_range_outlined),
            ),
          ],
          selected: {plan.scheduleMode},
          onSelectionChanged: (next) {
            plan.scheduleMode = next.first;
            if (plan.scheduleMode == ScheduleMode.week &&
                plan.weekdayMap.isEmpty) {
              plan.weekdayMap = sequentialWeekdayMap(plan.days);
            }
            onChanged();
          },
        ),
        if (plan.scheduleMode == ScheduleMode.once) ...[
          const SizedBox(height: 12),
          Text(
            'Workout sequence only until finished. No Rest days — use Skip day on Today to pass a workout.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (plan.scheduleMode == ScheduleMode.week) ...[
          const SizedBox(height: 16),
          Text('Weekday map', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Each weekday belongs to one workout. Picking a day already used moves it here. Unmapped weekdays are Rest.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final day in plan.days)
            if (day.blocks.isNotEmpty) _dayMapRow(context, day),
          if (unassigned.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              key: const Key('unassigned-weekday-warning'),
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unassigned.length == 1
                            ? '“${unassigned.first.title}” needs a weekday.'
                            : '${unassigned.length} workouts need a weekday: '
                                '${unassigned.map((d) => d.title).join(', ')}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _weekStripPreview(context),
        ],
      ],
    );
  }

  Widget _dayMapRow(BuildContext context, PlanDay day) {
    final theme = Theme.of(context);
    final selected = weekdaysForDay(plan, day.dayId).toSet();
    final missing = selected.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  key: Key('weekday-${day.dayId}-$weekday'),
                  label: Text(weekdayLabels[weekday]!),
                  selected: selected.contains(weekday),
                  onSelected: (on) {
                    final next = selected.toList();
                    if (on) {
                      next.add(weekday);
                    } else {
                      next.remove(weekday);
                    }
                    setWeekdaysForDay(plan, day.dayId, next);
                    onChanged();
                  },
                ),
            ],
          ),
          if (missing) ...[
            const SizedBox(height: 4),
            Text(
              'Assign at least one weekday.',
              key: Key('unassigned-day-${day.dayId}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weekStripPreview(BuildContext context) {
    final theme = Theme.of(context);
    final claimed = <int, String>{};
    for (final entry in plan.weekdayMap) {
      String? title;
      for (final day in plan.days) {
        if (day.dayId == entry.dayId) {
          title = day.title;
          break;
        }
      }
      for (final w in entry.weekdays) {
        claimed[w] = title ?? 'Day';
      }
    }
    return Row(
      children: [
        for (var weekday = 1; weekday <= 7; weekday++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: claimed.containsKey(weekday)
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    weekdayLabels[weekday]!,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    claimed[weekday] ?? 'Rest',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: claimed.containsKey(weekday)
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
