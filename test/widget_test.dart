import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/main.dart';

void main() {
  testWidgets('welcome route offers the import and create fork',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Lottie animates forever, so advance frames instead of settling.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Import a plan'), findsOneWidget);
    expect(find.text('Create a plan'), findsOneWidget);
  });
}
