import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Paths for CueLift brand bitmaps under `assets/image/brand/`.
abstract final class CueLiftBrandAssets {
  static const welcome = 'assets/image/brand/cuelift-welcome.png';
  static const icon = 'assets/image/brand/cuelift-icon.png';
  static const lockup = 'assets/image/brand/cuelift-lockup.png';
  static const markLight = 'assets/image/brand/cuelift-mark-light.png';
}

/// Welcome / splash brand stack (C + CueLift + assist line artwork).
class CueLiftWelcomeBrand extends StatelessWidget {
  const CueLiftWelcomeBrand({
    super.key,
    this.height = 280,
    this.showLoader = false,
  });

  final double height;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          CueLiftBrandAssets.welcome,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'CueLift',
        ),
        if (showLoader) ...[
          const SizedBox(height: 28),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              key: Key('app-boot'),
              strokeWidth: 3,
              color: CueLiftColors.coral,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small C mark for app bars and compact chrome.
class CueLiftAppMark extends StatelessWidget {
  const CueLiftAppMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      CueLiftBrandAssets.icon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'CueLift',
    );
  }
}
