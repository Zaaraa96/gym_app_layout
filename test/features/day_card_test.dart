import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/data/memory_plan_repository.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/day_card_summary.dart';
import 'package:gym_app/features/plans/plan_page.dart';
import 'package:gym_app/features/plans/rotating_exercise_thumbnail.dart';

import '../helpers/ports.dart';

WorkoutPlan _plan(List<PlanDay> days) {
  return WorkoutPlan.create(
    uuid: 'plan-uuid',
    title: 'Strength Builder',
    source: PlanSource.created,
    createdAt: DateTime.utc(2026, 9, 8),
    updatedAt: DateTime.utc(2026, 9, 8),
    days: days,
  );
}

ExercisePrescription _ex({
  required String id,
  required String title,
  int sets = 3,
  int? reps,
  int? duration,
}) {
  return ExercisePrescription.create(
    prescriptionId: id,
    title: title,
    prescribedSets: sets,
    prescribedReps: reps,
    prescribedDurationSeconds: duration,
  );
}

Future<void> _open(WidgetTester tester, WorkoutPlan plan) async {
  final plans = MemoryPlanRepository();
  await plans.save(plan);
  await tester.pumpWidget(
    GetMaterialApp(
      home: PlanPage(planId: plan.uuid, ports: testPorts(plans: plans)),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(Get.reset);

  testWidgets('unmatched custom day stays a flat info card', (tester) async {
    await _open(
      tester,
      _plan([
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [_ex(id: 'p1', title: 'mystery move', reps: 12)],
            ),
          ],
        ),
      ]),
    );

    expect(find.text('Day 1'), findsOneWidget);
    expect(find.byKey(const Key('day-card-thumbnails')), findsNothing);
    expect(find.byKey(const Key('day-card-focus')), findsNothing);
    expect(find.byKey(const Key('day-card-chip-abs')), findsNothing);
    expect(find.text('1 exercise · 3 sets'), findsOneWidget);
    expect(find.textContaining('mystery move'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('catalog plank day shows Core chips, estimate, and a still',
      (tester) async {
    await _open(
      tester,
      _plan([
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [
                _ex(id: 'p1', title: 'plank', sets: 3, duration: 30),
              ],
            ),
          ],
        ),
      ]),
    );

    expect(find.byKey(const Key('day-card-focus')), findsOneWidget);
    expect(find.text('Core'), findsWidgets);
    expect(find.byKey(const Key('day-card-chip-abs')), findsOneWidget);
    expect(find.byKey(const Key('day-card-chip-core')), findsOneWidget);
    expect(find.text('~5 min'), findsOneWidget);
    expect(find.text('1 exercise · 3 sets'), findsOneWidget);
    expect(find.byType(RotatingExerciseThumbnail), findsOneWidget);
  });

  testWidgets('several catalog stills rotate while the card is current',
      (tester) async {
    await _open(
      tester,
      _plan([
        PlanDay.create(
          dayId: 'day-1',
          title: 'Day 1',
          blocks: [
            ExerciseBlock.create(
              blockId: 'b1',
              kind: BlockKind.single,
              exercises: [_ex(id: 'p1', title: 'squat', reps: 10)],
            ),
            ExerciseBlock.create(
              blockId: 'b2',
              kind: BlockKind.single,
              exercises: [
                _ex(id: 'p2', title: 'plank', sets: 1, duration: 30),
              ],
            ),
          ],
        ),
      ]),
    );

    expect(
      find.byKey(const ValueKey('assets/image/exercises/squat.png')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('assets/image/exercises/plank.png')),
      findsNothing,
    );

    await tester.pump(dayCardThumbnailInterval);
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey('assets/image/exercises/plank.png')),
      findsOneWidget,
    );
  });

  testWidgets('rotation pauses under a pushed route so settle can finish',
      (tester) async {
    final plans = MemoryPlanRepository();
    final plan = _plan([
      PlanDay.create(
        dayId: 'day-1',
        title: 'Day 1',
        blocks: [
          ExerciseBlock.create(
            blockId: 'b1',
            kind: BlockKind.single,
            exercises: [_ex(id: 'p1', title: 'squat', reps: 10)],
          ),
          ExerciseBlock.create(
            blockId: 'b2',
            kind: BlockKind.single,
            exercises: [_ex(id: 'p2', title: 'plank', sets: 1, duration: 30)],
          ),
        ],
      ),
    ]);
    await plans.save(plan);
    await tester.pumpWidget(
      GetMaterialApp(
        home: PlanPage(planId: plan.uuid, ports: testPorts(plans: plans)),
      ),
    );
    await tester.pump();
    await tester.pump();

    Navigator.of(tester.element(find.byType(PlanPage))).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('editor')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsOneWidget);
  });
}
