import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Shared filled / outlined action button.
///
/// Primary (filled) buttons use a light press scale per design-system motion.
class AppElevatedButton extends StatefulWidget {
  const AppElevatedButton({
    super.key,
    required this.onPressed,
    required this.data,
    this.outlined = false,
  });

  final String data;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  State<AppElevatedButton> createState() => _AppElevatedButtonState();
}

class _AppElevatedButtonState extends State<AppElevatedButton> {
  late final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.outlined
        ? OutlinedButton(
            statesController: _states,
            onPressed: widget.onPressed,
            child: Text(widget.data),
          )
        : ElevatedButton(
            statesController: _states,
            onPressed: widget.onPressed,
            child: Text(widget.data),
          );

    // Primary CTA only — outlined actions stay flat.
    if (widget.outlined) return child;

    return ListenableBuilder(
      listenable: _states,
      builder: (context, _) {
        final pressed = _states.value.contains(WidgetState.pressed) &&
            widget.onPressed != null;
        return AnimatedScale(
          scale: pressed ? CueLiftMotion.ctaPressScale : 1,
          duration: CueLiftMotion.ctaPress,
          curve: CueLiftMotion.ctaCurve,
          child: child,
        );
      },
    );
  }
}
