import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Isar generated schemas do not use JavaScript-unsafe integer literals',
      () {
    final idLiteral = RegExp(r'id:\s*(-?\d+)\s*,');
    const maxSafe = 9007199254740991;
    final dir = Directory('lib/data/isar');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.g.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty, reason: 'expected generated Isar schemas');
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
