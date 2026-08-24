import 'dart:math';

final _random = Random();

/// Unique string ids for nested plan entities (days, blocks, prescriptions).
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
