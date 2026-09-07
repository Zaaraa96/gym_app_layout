import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/models/models.dart';
import 'package:gym_app/features/plans/import_preview_page.dart';

import '../helpers/ports.dart';

void main() {
  testWidgets('legacy common-plan conversion is explained on preview',
      (tester) async {
    final now = DateTime.utc(2026, 9, 7);
    final plan = WorkoutPlan.create(
      title: 'plan 1',
      source: PlanSource.imported,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(dayId: 'd1', title: 'day 1'),
        PlanDay.create(dayId: 'd2', title: 'abs'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ImportPreviewPage(
          fileName: 'plan.json',
          plan: plan,
          convertedCommonSectionTitles: const ['abs', 'corrective'],
          ports: testPorts(),
        ),
      ),
    );

    expect(find.text('Former common sections'), findsOneWidget);
    expect(
      find.textContaining('They are now regular days: abs, corrective.'),
      findsOneWidget,
    );
  });
}
