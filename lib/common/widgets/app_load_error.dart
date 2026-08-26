import 'package:flutter/material.dart';

import 'app_elevated_button.dart';
import 'app_text.dart';

/// Shown when a screen cannot read Isar. Retry runs the same load again.
class AppLoadError extends StatelessWidget {
  const AppLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            message,
            style: subtitleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppElevatedButton(data: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
