import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/plans/native_file_label.dart';

void main() {
  test('exact filename matches', () {
    expect(nativeFileLabelMatches('plan.json', 'plan.json'), isTrue);
    expect(nativeFileLabelMatches('invalid-plan.json', 'invalid-plan.json'), isTrue);
  });

  test('plan.json does not match invalid-plan.json', () {
    expect(nativeFileLabelMatches('invalid-plan.json', 'plan.json'), isFalse);
    expect(nativeFileLabelMatches('plan.json', 'invalid-plan.json'), isFalse);
  });

  test('filename may be followed by size or type, not more name', () {
    expect(nativeFileLabelMatches('plan.json 1 KB', 'plan.json'), isTrue);
    expect(nativeFileLabelMatches('plan.json\nJSON', 'plan.json'), isTrue);
    expect(nativeFileLabelMatches('plan.json.bak', 'plan.json'), isFalse);
  });

  test('exact match ignores a wrapped suffix line', () {
    expect(nativeFileLabelIsExact('plan.json', 'plan.json'), isTrue);
    expect(nativeFileLabelIsExact('invalid-plan.json', 'plan.json'), isFalse);
    expect(nativeFileLabelIsExact('plan.json 1 KB', 'plan.json'), isFalse);
  });

  test('DocumentsUI may wrap a long .gymplan name onto two lines', () {
    expect(
      nativeFileLabelMatches('valid-plan.\ngymplan', 'valid-plan.gymplan'),
      isTrue,
    );
    expect(
      nativeFileLabelMatches('pack.gymplan\nZIP archive', 'pack.gymplan'),
      isTrue,
    );
    expect(
      nativeFileLabelIsExact('pack.\ngymplan', 'pack.gymplan'),
      isTrue,
    );
  });
}
