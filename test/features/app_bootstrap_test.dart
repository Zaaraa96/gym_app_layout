import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/main.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('the first frame is a themed loader, not an empty route',
      (tester) async {
    final boot = Completer<String>();
    await tester.pumpWidget(AppBootstrap(boot: () => boot.future));

    expect(find.byKey(const Key('app-boot')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(GetMaterialApp), findsNothing);
  });

  testWidgets('a failed boot shows retry instead of staying blank',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      AppBootstrap(
        boot: () async {
          calls += 1;
          if (calls == 1) {
            throw StateError('isar locked');
          }
          return AppRoutes.welcome;
        },
      ),
    );
    await tester.pump();

    expect(find.textContaining('Could not open the app'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(calls, 2);
    expect(find.text('Welcome To the Amazing Gym app'), findsOneWidget);
  });
}
