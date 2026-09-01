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
}
