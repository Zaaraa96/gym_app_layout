import 'package:flutter_test/flutter_test.dart';

/// Probe to confirm GitHub Actions runs `flutter test` on pull requests.
void main() {
  test('CI smoke: one plus one is two', () {
    expect(1 + 1, 2);
  });
}
