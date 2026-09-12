import 'package:flutter/material.dart';

/// Shared text styles. Colors resolve from the active [Theme] inside [AppText].
const titleTextStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: 20);

const subtitleTextStyle = TextStyle(fontWeight: FontWeight.w200);

const dataTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  const AppText(this.data, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: resolveAppTextStyle(context, style),
      textAlign: textAlign,
    );
  }
}

/// Fills missing colors on shared styles so light and dark themes stay readable.
TextStyle? resolveAppTextStyle(BuildContext context, TextStyle? style) {
  if (style == null) return null;
  if (style.color != null) return style;

  final scheme = Theme.of(context).colorScheme;
  final Color color;
  if (style.fontWeight == FontWeight.w900) {
    color = scheme.primary;
  } else if (style.fontWeight == FontWeight.w200) {
    color = scheme.onSurfaceVariant;
  } else {
    color = scheme.onSurface;
  }
  return style.copyWith(color: color);
}
