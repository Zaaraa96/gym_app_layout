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
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant AppElevatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _pressed) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.outlined
        ? OutlinedButton(
            onPressed: widget.onPressed,
            child: Text(widget.data),
          )
        : ElevatedButton(
            onPressed: widget.onPressed,
            child: Text(widget.data),
          );

    // Primary CTA only — outlined actions stay flat.
    if (widget.outlined) return child;

    // Drive press scale from pointer events instead of WidgetStatesController.
    // Material buttons update disabled on the controller during mount; listening
    // to that from an ancestor ListenableBuilder marks AnimatedScale dirty
    // mid-build (setState during build) when onPressed is null.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && _enabled ? CueLiftMotion.ctaPressScale : 1,
        duration: CueLiftMotion.ctaPress,
        curve: CueLiftMotion.ctaCurve,
        child: child,
      ),
    );
  }
}
