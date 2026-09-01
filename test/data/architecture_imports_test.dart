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
}
