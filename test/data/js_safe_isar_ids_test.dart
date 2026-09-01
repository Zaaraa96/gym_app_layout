import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Isar generated schemas do not use JavaScript-unsafe integer literals',
      () {
    final idLiteral = RegExp(r'id:\s*(-?\d+)\s*,');
    const maxSafe = 9007199254740991;
    final files = [
      File('lib/data/isar/workout_plan.g.dart'),
      File('lib/data/isar/workout_session.g.dart'),
    ];
    final offenders = <String>[];
    for (final file in files) {
      for (final match in idLiteral.allMatches(file.readAsStringSync())) {
        final value = int.parse(match.group(1)!);
        if (value.abs() > maxSafe) {
          offenders.add('${file.path}: ${match.group(0)}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });
}
