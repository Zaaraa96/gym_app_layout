import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/domain/new_id.dart';

void main() {
  test('newUuid is an RFC 4122 version-4 UUID', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = <String>{};
    for (var i = 0; i < 40; i++) {
      final uuid = newUuid();
      expect(uuid, matches(pattern));
      ids.add(uuid);
    }
    expect(ids, hasLength(40));
  });

  test('newId is unique for nested plan entity ids', () {
    final ids = {for (var i = 0; i < 40; i++) newId()};
    expect(ids, hasLength(40));
    expect(ids.every((id) => id.contains('-')), isTrue);
  });
}
