import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/data/app_ports.dart';
import 'package:gym_app/data/isar_service.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';
import 'package:gym_app/data/session_lifecycle.dart';
import 'package:gym_app/data/session_repository.dart';
import 'package:gym_app/features/plans/day_preview_page.dart';
import 'package:gym_app/main.dart';

import '../helpers/isar_core.dart';

/// Step 4: plan day cards open a read-only day preview with reps and duration
/// rows loaded from Isar. Edit stays a separate action.
void main() {
  Directory? tempDir;
  var instanceSeq = 0;

  setUpAll(() async {
    await ensureIsarCore();
    tempDir = await Directory.systemTemp.createTemp('gym_app_day_preview_');
  });

  tearDown(() async {
    if (Get.isRegistered<IsarService>()) {
      await IsarService.to.close(deleteFromDisk: true);
    }
    Get.reset();
  });

  tearDownAll(() async {
    final dir = tempDir;
    if (dir != null && dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  Future<T> db<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  Future<PlanRepository> bootstrap(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    instanceSeq += 1;
    final service = await db(
      tester,
      () => IsarService.init(
        directory: tempDir!.path,
        name: 'dayPreview$instanceSeq',
      ),
    );
    Get.put<IsarService>(service, permanent: true);
    putSessions(service.isar);
    return putPlans(service.isar);
  }

  Future<void> settle(WidgetTester tester) => settleApp(tester);

  Future<void> launch(WidgetTester tester, String route) async {
    await tester.pumpWidget(MyApp(initialRoute: route));
    await tester.pump(const Duration(milliseconds: 100));
    await settle(tester);
  }

  WorkoutPlan samplePlan() {
    final now = DateTime.utc(2026, 8, 26, 12);
    return WorkoutPlan.create(
      title: 'plan 1',
      source: PlanSource.imported,
      createdAt: now,
      updatedAt: now,
      days: [
        PlanDay.create(
          dayId: 'day-1',
          title: 'day 1- 4sar',
          summary: 'legs',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-ss',
              kind: BlockKind.superset,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-kang',
                  title: 'kang squat',
                  prescribedSets: 3,
                  prescribedReps: 12,
                ),
                ExercisePrescription.create(
                  prescriptionId: 'p-leg',
                  title: 'leg extension',
                  prescribedSets: 3,
                  prescribedReps: 12,
                ),
              ],
            ),
            ExerciseBlock.create(
              blockId: 'block-hold',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-plank',
                  title: 'plank',
                  prescribedSets: 1,
                  prescribedDurationSeconds: 30,
                ),
              ],
            ),
          ],
        ),
      ],
      commonSections: [
        CommonSection.create(
          sectionId: 'sec-abs',
          title: 'abs',
          blocks: [
            ExerciseBlock.create(
              blockId: 'block-abs',
              kind: BlockKind.single,
              exercises: [
                ExercisePrescription.create(
                  prescriptionId: 'p-shoot',
                  title: 'shoot out',
                  prescribedSets: 1,
                  prescribedDurationSeconds: 30,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  testWidgets(
    'opening a day shows reps, duration, and the start CTA from Isar',
    (tester) async {
      final plans = await bootstrap(tester);
      await db(tester, () => plans.save(samplePlan()));

      await launch(tester, AppRoutes.home);
      expect(find.text('plan 1'), findsOneWidget);

      await tester.tap(find.text('plan 1'));
      await tester.pump();
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.plan);
      expect(find.text('day 1- 4sar'), findsOneWidget);
      expect(find.text('legs'), findsOneWidget);
      expect(
        find.text('3 × 12 kang squat + 3 × 12 leg extension'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('day-card-day-1')));
      await tester.pump();
      await settle(tester);

      expect(Get.currentRoute, AppRoutes.day);
      expect(find.text('day 1- 4sar'), findsWidgets);
      expect(find.text('legs'), findsWidgets);
      expect(find.text('kang squat'), findsOneWidget);
      expect(find.text('x12'), findsNWidgets(2));
      expect(find.text('leg extension'), findsOneWidget);
      expect(find.text('plank'), findsOneWidget);
      expect(find.text('x30s'), findsOneWidget);
      expect(find.byKey(const Key('block-row-block-ss')), findsOneWidget);
      expect(find.byKey(const Key('block-row-block-hold')), findsOneWidget);
      expect(
        find.text('Common sections can be included when you start.'),
        findsOneWidget,
      );
      expect(find.text('Start workout'), findsOneWidget);

      await tester.tap(find.text('Start workout'));
      await tester.pump();
      await settle(tester);
      expect(find.text('Include today'), findsOneWidget);
      expect(find.text('abs'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-include')));
      await tester.pump();
      await settle(tester);

      expect(find.text('kang squat'), findsWidgets);
      expect(find.text('Log what you did on this set.'), findsOneWidget);
      expect(find.text('Log set'), findsOneWidget);
    },
  );

  testWidgets(
    'Start is disabled when the day is empty and there are no commons',
    (tester) async {
      final plans = await bootstrap(tester);
      final now = DateTime.utc(2026, 8, 26, 12);
      await db(
        tester,
        () => plans.save(
          WorkoutPlan.create(
            title: 'empty day plan',
            source: PlanSource.created,
            createdAt: now,
            updatedAt: now,
            days: [PlanDay.create(dayId: 'day-empty', title: 'empty day')],
          ),
        ),
      );

      await launch(tester, AppRoutes.home);
      await tester.tap(find.text('empty day plan'));
      await tester.pump();
      await settle(tester);
      await tester.tap(find.byKey(const Key('day-card-day-empty')));
      await tester.pump();
      await settle(tester);

      final start = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start workout'),
      );
      expect(start.onPressed, isNull);
    },
  );

  testWidgets(
    'Start stays enabled when the day is empty but the plan has commons',
    (tester) async {
      final plans = await bootstrap(tester);
      final now = DateTime.utc(2026, 8, 26, 12);
      await db(
        tester,
        () => plans.save(
          WorkoutPlan.create(
            title: 'commons only',
            source: PlanSource.created,
            createdAt: now,
            updatedAt: now,
            days: [PlanDay.create(dayId: 'day-empty', title: 'empty day')],
            commonSections: [
              CommonSection.create(sectionId: 'sec-abs', title: 'abs'),
            ],
          ),
        ),
      );

      await launch(tester, AppRoutes.home);
      await tester.tap(find.text('commons only'));
      await tester.pump();
      await settle(tester);
      await tester.tap(find.byKey(const Key('day-card-day-empty')));
      await tester.pump();
      await settle(tester);

      final start = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start workout'),
      );
      expect(start.onPressed, isNotNull);
    },
  );

  testWidgets('edit day from preview opens the day editor', (tester) async {
    final plans = await bootstrap(tester);
    await db(tester, () => plans.save(samplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('plan 1'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Edit day'), findsOneWidget);
    await tester.tap(find.text('Edit day'));
    await tester.pump();
    await settle(tester);

    expect(Get.currentRoute, AppRoutes.editDay);
    expect(find.text('Add exercise'), findsWidgets);
  });

  testWidgets('starting a different day offers to resume the live session', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final plan = _twoDayPlan();
    await db(tester, () => plans.save(plan));
    await db(
      tester,
      () => SessionLifecycle(sessions).start(
        plan: plan,
        planDayId: 'day-a',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('A/B'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-b')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await settle(tester);

    expect(find.text('A workout is already in progress'), findsOneWidget);
    final resume = find.byKey(const Key('resume-existing'));
    await tester.ensureVisible(resume);
    await tester.tap(resume);
    await tester.pump();
    await settle(tester);

    expect(find.text('squat  ·  set 1 of 2'), findsOneWidget);
    expect(find.text('Log set'), findsOneWidget);
  });

  testWidgets('abandon and start this day closes the live session', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final plan = _twoDayPlan();
    await db(tester, () => plans.save(plan));
    final live = await db(
      tester,
      () => SessionLifecycle(sessions).start(
        plan: plan,
        planDayId: 'day-a',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('A/B'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-b')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await settle(tester);
    expect(find.text('A workout is already in progress'), findsOneWidget);

    final abandon = find.byKey(const Key('abandon-and-start'));
    await tester.ensureVisible(abandon);
    await tester.tap(abandon);
    await tester.pump();
    await settle(tester);
    await settle(tester);

    expect(find.text('A workout is already in progress'), findsNothing);
    expect(find.text('Log set'), findsOneWidget);
    expect(find.textContaining('push up'), findsWidgets);
    final abandoned = await db(tester, () => sessions.byId(live.id));
    expect(abandoned!.status, SessionStatus.abandoned);
    final current = await db(tester, () => sessions.inProgress());
    expect(current!.planDayId, 'day-b');
  });

  testWidgets(
    'starting the same live day resumes it without a conflict dialog',
    (tester) async {
      final plans = await bootstrap(tester);
      final sessions = Get.find<SessionRepository>();
      final plan = _twoDayPlan();
      await db(tester, () => plans.save(plan));
      await db(
        tester,
        () => SessionLifecycle(sessions).start(
          plan: plan,
          planDayId: 'day-a',
          startedAt: DateTime.utc(2026, 8, 28, 12),
        ),
      );

      await launch(tester, AppRoutes.home);
      await tester.tap(find.text('A/B'));
      await tester.pump();
      await settle(tester);
      await tester.tap(find.byKey(const Key('day-card-day-a')));
      await tester.pump();
      await settle(tester);

      await tester.tap(find.text('Start workout'));
      await tester.pump();
      await settle(tester);

      expect(find.text('A workout is already in progress'), findsNothing);
      expect(find.text('squat  ·  set 1 of 2'), findsOneWidget);
      expect(find.text('Log set'), findsOneWidget);
      final live = await db(tester, () => sessions.inProgress());
      expect(live!.planDayId, 'day-a');
    },
  );

  testWidgets('cancel on a live-session conflict leaves the existing workout', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final plan = _twoDayPlan();
    await db(tester, () => plans.save(plan));
    final live = await db(
      tester,
      () => SessionLifecycle(sessions).start(
        plan: plan,
        planDayId: 'day-a',
        startedAt: DateTime.utc(2026, 8, 28, 12),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('A/B'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-b')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await settle(tester);
    expect(find.text('A workout is already in progress'), findsOneWidget);

    final cancel = find.widgetWithText(TextButton, 'Cancel');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    await settle(tester);

    expect(find.text('A workout is already in progress'), findsNothing);
    expect(find.text('Log set'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
    final stillLive = await db(tester, () => sessions.inProgress());
    expect(stillLive!.id, live.id);
    expect(stillLive.status, SessionStatus.inProgress);
  });

  testWidgets('cancel on Include today does not start a session', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    await db(tester, () => plans.save(samplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('plan 1'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await settle(tester);
    expect(find.text('Include today'), findsOneWidget);

    final cancel = find.widgetWithText(TextButton, 'Cancel');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    await settle(tester);

    expect(find.text('Include today'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Log set'), findsNothing);
    expect(await db(tester, () => sessions.inProgress()), isNull);
  });

  testWidgets('turning on a common section copies it into the live session', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    await db(tester, () => plans.save(samplePlan()));

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('plan 1'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-1')));
    await tester.pump();
    await settle(tester);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    await settle(tester);
    expect(find.text('Include today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('include-section-sec-abs')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-include')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Log set'), findsOneWidget);
    final live = await db(tester, () => sessions.inProgress());
    expect(live!.includedCommonSectionIds, ['sec-abs']);
    expect(live.exerciseLogs.map((log) => log.exerciseTitle), [
      'kang squat',
      'leg extension',
      'plank',
      'shoot out',
    ]);
    expect(live.exerciseLogs.last.fromCommonSection, isTrue);
  });

  testWidgets(
    'starting with every common section off keeps extras out of the session',
    (tester) async {
      final plans = await bootstrap(tester);
      final sessions = Get.find<SessionRepository>();
      await db(tester, () => plans.save(samplePlan()));

      await launch(tester, AppRoutes.home);
      await tester.tap(find.text('plan 1'));
      await tester.pump();
      await settle(tester);
      await tester.tap(find.byKey(const Key('day-card-day-1')));
      await tester.pump();
      await settle(tester);

      await tester.tap(find.text('Start workout'));
      await tester.pump();
      await settle(tester);
      expect(find.text('Include today'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-include')));
      await tester.pump();
      await settle(tester);

      expect(find.text('Log set'), findsOneWidget);
      final live = await db(tester, () => sessions.inProgress());
      expect(live!.includedCommonSectionIds, isEmpty);
      expect(live.exerciseLogs.map((log) => log.exerciseTitle), [
        'kang squat',
        'leg extension',
        'plank',
      ]);
      expect(
        live.exerciseLogs.every((log) => log.fromCommonSection == false),
        isTrue,
      );
    },
  );

  testWidgets(
    'starting an empty day without turning on commons shows a snackbar',
    (tester) async {
      final plans = await bootstrap(tester);
      final now = DateTime.utc(2026, 8, 26, 12);
      await db(
        tester,
        () => plans.save(
          WorkoutPlan.create(
            title: 'commons only',
            source: PlanSource.created,
            createdAt: now,
            updatedAt: now,
            days: [PlanDay.create(dayId: 'day-empty', title: 'empty day')],
            commonSections: [
              CommonSection.create(
                sectionId: 'sec-abs',
                title: 'abs',
                blocks: [
                  ExerciseBlock.create(
                    blockId: 'block-abs',
                    kind: BlockKind.single,
                    exercises: [
                      ExercisePrescription.create(
                        prescriptionId: 'p-plank',
                        title: 'plank',
                        prescribedSets: 1,
                        prescribedDurationSeconds: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await launch(tester, AppRoutes.home);
      await tester.tap(find.text('commons only'));
      await tester.pump();
      await settle(tester);
      await tester.tap(find.byKey(const Key('day-card-day-empty')));
      await tester.pump();
      await settle(tester);

      expect(find.text('empty day'), findsWidgets);
      final start = find.widgetWithText(ElevatedButton, 'Start workout');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump();
      await settle(tester);
      expect(find.text('Include today'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-include')));
      await tester.pump();
      await settle(tester);

      expect(
        find.text('Turn on a section or add an exercise first.'),
        findsOneWidget,
      );
      expect(find.text('Log set'), findsNothing);
    },
  );

  testWidgets('an empty day starts when a common section is turned on', (
    tester,
  ) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final now = DateTime.utc(2026, 8, 26, 12);
    await db(
      tester,
      () => plans.save(
        WorkoutPlan.create(
          title: 'commons only',
          source: PlanSource.created,
          createdAt: now,
          updatedAt: now,
          days: [PlanDay.create(dayId: 'day-empty', title: 'empty day')],
          commonSections: [
            CommonSection.create(
              sectionId: 'sec-abs',
              title: 'abs',
              blocks: [
                ExerciseBlock.create(
                  blockId: 'block-abs',
                  kind: BlockKind.single,
                  exercises: [
                    ExercisePrescription.create(
                      prescriptionId: 'p-plank',
                      title: 'plank',
                      prescribedSets: 1,
                      prescribedDurationSeconds: 30,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('commons only'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-empty')));
    await tester.pump();
    await settle(tester);

    final start = find.widgetWithText(ElevatedButton, 'Start workout');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    await settle(tester);
    expect(find.text('Include today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('include-section-sec-abs')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-include')));
    await tester.pump();
    await settle(tester);

    expect(find.text('Log time'), findsOneWidget);
    expect(find.text('Log set'), findsNothing);
    expect(find.text('plank  ·  set 1 of 1'), findsOneWidget);
    final live = await db(tester, () => sessions.inProgress());
    expect(live!.includedCommonSectionIds, ['sec-abs']);
    expect(live.exerciseLogs.single.exerciseTitle, 'plank');
    expect(live.exerciseLogs.single.fromCommonSection, isTrue);
    expect(live.planDayId, 'day-empty');
  });

  testWidgets(
      'turning on a section starts an empty day with only those extras',
      (tester) async {
    final plans = await bootstrap(tester);
    final sessions = Get.find<SessionRepository>();
    final now = DateTime.utc(2026, 8, 26, 12);
    await db(
      tester,
      () => plans.save(
        WorkoutPlan.create(
          title: 'commons only',
          source: PlanSource.created,
          createdAt: now,
          updatedAt: now,
          days: [
            PlanDay.create(dayId: 'day-empty', title: 'empty day'),
          ],
          commonSections: [
            CommonSection.create(
              sectionId: 'sec-abs',
              title: 'abs',
              blocks: [
                ExerciseBlock.create(
                  blockId: 'block-abs',
                  kind: BlockKind.single,
                  exercises: [
                    ExercisePrescription.create(
                      prescriptionId: 'p-plank',
                      title: 'plank',
                      prescribedSets: 1,
                      prescribedDurationSeconds: 30,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await launch(tester, AppRoutes.home);
    await tester.tap(find.text('commons only'));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.byKey(const Key('day-card-day-empty')));
    await tester.pump();
    await settle(tester);

    final start = find.widgetWithText(ElevatedButton, 'Start workout');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    await settle(tester);

    await tester.tap(find.byKey(const Key('include-section-sec-abs')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-include')));
    await tester.pump();
    await settle(tester);

    expect(find.text('plank  ·  set 1 of 1'), findsOneWidget);
    expect(find.text('Log time'), findsOneWidget);
    expect(find.text('Log set'), findsNothing);
    final live = await db(tester, () => sessions.inProgress());
    expect(live, isNotNull);
    expect(live!.planDayId, 'day-empty');
    expect(live.includedCommonSectionIds, ['sec-abs']);
    expect(live.exerciseLogs, hasLength(1));
    expect(live.exerciseLogs.single.exerciseTitle, 'plank');
    expect(live.exerciseLogs.single.fromCommonSection, isTrue);
    expect(live.exerciseLogs.single.prescribedDurationSeconds, 30);
  });

  testWidgets('a missing day says it is no longer here', (tester) async {
    final plans = await bootstrap(tester);
    final plan = samplePlan();
    await db(tester, () => plans.save(plan));

    await tester.pumpWidget(
      GetMaterialApp(
        home: DayPreviewPage(
          planId: plan.uuid,
          dayId: 'missing-day',
          ports: Get.find<AppPorts>(),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('This day is no longer here.'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
  });
}

WorkoutPlan _twoDayPlan() {
  final now = DateTime.utc(2026, 8, 28, 12);
  ExerciseBlock single(String id, String title) => ExerciseBlock.create(
    blockId: 'block-$id',
    kind: BlockKind.single,
    exercises: [
      ExercisePrescription.create(
        prescriptionId: 'p-$id',
        title: title,
        prescribedSets: 2,
        prescribedReps: 10,
      ),
    ],
  );
  return WorkoutPlan.create(
    title: 'A/B',
    source: PlanSource.created,
    createdAt: now,
    updatedAt: now,
    days: [
      PlanDay.create(
        dayId: 'day-a',
        title: 'Day A',
        blocks: [single('a', 'squat')],
      ),
      PlanDay.create(
        dayId: 'day-b',
        title: 'Day B',
        blocks: [single('b', 'push up')],
      ),
    ],
  );
}
