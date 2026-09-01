import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only Isar implementations import the concrete repository classes', () {
    final root = Directory('lib');
    final offenders = <String>[];
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('isar_plan_repository.dart')) continue;
      if (file.path.endsWith('isar_session_repository.dart')) continue;
      if (file.path.endsWith('main.dart')) continue;
      final source = file.readAsStringSync();
      if (source.contains('isar_plan_repository.dart') ||
          source.contains('isar_session_repository.dart')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });

  test('repository interfaces and SessionLifecycle do not import Isar', () {
    for (final relative in [
      'lib/data/plan_repository.dart',
      'lib/data/session_repository.dart',
      'lib/data/session_lifecycle.dart',
    ]) {
      final source = File(relative).readAsStringSync();
      expect(
        source.contains("package:isar/isar.dart"),
        isFalse,
        reason: '$relative must stay Isar-free',
      );
    }
  });

  test('product types do not import Isar or use @collection / Id / indexes', () {
    final files = [
      'lib/data/models/workout_plan.dart',
      'lib/data/models/workout_session.dart',
      'lib/data/models/enums.dart',
      'lib/data/models/models.dart',
    ];
    for (final relative in files) {
      final source = File(relative).readAsStringSync();
      expect(
        source.contains("package:isar/isar.dart"),
        isFalse,
        reason: '$relative must stay Isar-free',
      );
      expect(source.contains('@collection'), isFalse, reason: relative);
      expect(source.contains('@embedded'), isFalse, reason: relative);
      expect(source.contains('@Index'), isFalse, reason: relative);
      expect(source.contains('@enumerated'), isFalse, reason: relative);
      expect(
        RegExp(r'\bId\b').hasMatch(source),
        isFalse,
        reason: '$relative must not use Isar Id',
      );
    }
  });

  test('memory repositories only know domain ids, not Isar.autoIncrement', () {
    for (final relative in [
      'lib/data/memory_plan_repository.dart',
      'lib/data/memory_session_repository.dart',
    ]) {
      final source = File(relative).readAsStringSync();
      expect(
        source.contains("package:isar/isar.dart"),
        isFalse,
        reason: '$relative must not import Isar',
      );
      expect(
        source.contains('Isar.autoIncrement'),
        isFalse,
        reason: '$relative must assign domain ids without Isar sentinels',
      );
    }
  });

  test('routes and pages key plans and sessions by uuid, not int row ids', () {
    for (final relative in [
      'lib/main.dart',
      'lib/features/plans/plan_page.dart',
      'lib/features/plans/day_preview_page.dart',
      'lib/features/plans/day_editor_page.dart',
      'lib/features/plans/plans_home_page.dart',
      'lib/features/plans/add_plan_page.dart',
      'lib/features/plans/import_preview_page.dart',
      'lib/features/workout/start_workout.dart',
      'lib/features/workout/live_workout_page.dart',
      'lib/features/workout/workout_controller.dart',
      'lib/features/progress/session_log_page.dart',
      'lib/features/progress/month_tab.dart',
    ]) {
      final source = File(relative).readAsStringSync();
      expect(
        source.contains('Get.arguments as int'),
        isFalse,
        reason: '$relative must not pass Isar row ids through routes',
      );
      expect(
        source.contains('final int planId'),
        isFalse,
        reason: '$relative must not take an int planId',
      );
      expect(
        source.contains('final int sessionId'),
        isFalse,
        reason: '$relative must not take an int sessionId',
      );
    }
  });

  test('pages call product use cases instead of assembling sessions', () {
    expect(
      File('lib/features/workout/start_workout.dart')
          .readAsStringSync()
          .contains('exerciseLogsForStart'),
      isFalse,
      reason: 'start dialogs must not assemble logs',
    );
    expect(
      File('lib/features/plans/plan_import_flow.dart')
          .readAsStringSync()
          .contains('JsonPlanImporter'),
      isFalse,
      reason: 'import flow must not parse JSON itself',
    );
    expect(
      File('lib/features/plans/plans_home_page.dart')
          .readAsStringSync()
          .contains('suggestToday('),
      isFalse,
      reason: 'home must not decide today from page state',
    );
    expect(
      File('lib/features/progress/month_tab.dart')
          .readAsStringSync()
          .contains('forMonth('),
      isFalse,
      reason: 'month tab must not fold repository rows itself',
    );
  });

  test('feature widgets do not look up repositories with Get.find', () {
    final offenders = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final needle in [
        'Get.find<PlanRepository>',
        'Get.find<SessionRepository>',
        'Get.find<SessionLifecycle>',
        'Get.find<PlanImport',
        'Get.find<StartSession>',
        'Get.find<AppPorts>',
      ]) {
        if (source.contains(needle)) {
          offenders.add('${file.path}: $needle');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });
}
