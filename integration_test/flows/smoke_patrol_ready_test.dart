import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Proves Patrol, the Android runner, and the AVD can talk to each other.
/// Does not launch the gym app (Welcome Lottie never settles).
void main() {
  patrolTest(
    'Patrol can pump a widget and reach the Android device',
    ($) async {
      await $.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Patrol ready')),
          ),
        ),
      );
      await $.pump();
      expect($('Patrol ready'), findsOneWidget);

      await $.platform.mobile.pressHome();
    },
  );
}
