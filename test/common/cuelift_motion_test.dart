import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/app_theme.dart';
import 'package:gym_app/common/widgets/app_elevated_button.dart';
import 'package:gym_app/common/widgets/cuelift_brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CueLiftMotion matches design-system durations', () {
    expect(CueLiftMotion.welcomeEntrance, const Duration(milliseconds: 400));
    expect(CueLiftMotion.ctaPressScale, lessThan(1));
    expect(CueLiftMotion.navIndicator.inMilliseconds, greaterThan(0));
  });

  testWidgets('Welcome brand entrance animation runs once', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CueLiftWelcomeBrand(
            height: 120,
            animateEntrance: true,
          ),
        ),
      ),
    );

    final state = tester.state<State>(find.byType(CueLiftWelcomeBrand));
    expect(state, isA<State>());

    // Mid-entrance: fade/slide controller is running.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FadeTransition), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.byType(CueLiftWelcomeBrand), findsOneWidget);
    expect(find.text('Your training assistant'), findsOneWidget);
  });

  testWidgets('primary CTA scales on press', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppElevatedButton(
            data: 'Go',
            onPressed: () {},
          ),
        ),
      ),
    );

    final scaleFinder = find.byType(AnimatedScale);
    expect(scaleFinder, findsOneWidget);
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1);

    final gesture = await tester.press(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, CueLiftMotion.ctaPressScale);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1);
  });

  testWidgets('outlined CTA does not scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppElevatedButton(
            outlined: true,
            data: 'Side',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedScale), findsNothing);
  });
}
