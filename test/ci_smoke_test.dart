import 'package:flutter_test/flutter_test.dart';

/// Probe to confirm GitHub Actions runs `flutter test` on pull requests.
void main() {
  test('CI smoke: one plus one is two', () {
    // Intentional mismatch so the first CI run on this PR fails.
    expect(1 + 1, 3);
  });
}
