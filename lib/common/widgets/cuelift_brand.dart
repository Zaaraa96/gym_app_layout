import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Paths for CueLift brand bitmaps under `assets/image/brand/`.
abstract final class CueLiftBrandAssets {
  static const welcome = 'assets/image/brand/cuelift-welcome.png';
  static const icon = 'assets/image/brand/cuelift-icon.png';
  static const markLight = 'assets/image/brand/cuelift-mark-light.png';
}

/// Welcome / splash brand stack (C + CueLift + assist line artwork).
///
/// When [animateEntrance] is true, the stack fades/slides in once over
/// [CueLiftMotion.welcomeEntrance] (design-system Welcome motion).
class CueLiftWelcomeBrand extends StatefulWidget {
  const CueLiftWelcomeBrand({
    super.key,
    this.height = 280,
    this.showLoader = false,
    this.animateEntrance = false,
  });

  final double height;
  final bool showLoader;
  final bool animateEntrance;

  @override
  State<CueLiftWelcomeBrand> createState() => _CueLiftWelcomeBrandState();
}

class _CueLiftWelcomeBrandState extends State<CueLiftWelcomeBrand>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _fade;
  Animation<Offset>? _slide;

  @override
  void initState() {
    super.initState();
    if (!widget.animateEntrance) return;
    _controller = AnimationController(
      vsync: this,
      duration: CueLiftMotion.welcomeEntrance,
    );
    _fade = CurvedAnimation(
      parent: _controller!,
      curve: CueLiftMotion.welcomeCurve,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: CueLiftMotion.welcomeCurve,
      ),
    );
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          CueLiftBrandAssets.welcome,
          height: widget.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'CueLift',
        ),
        if (widget.showLoader) ...[
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

    final controller = _controller;
    final fade = _fade;
    final slide = _slide;
    if (controller == null || fade == null || slide == null) {
      return stack;
    }

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: stack,
      ),
    );
  }
}

/// Small C mark for app bars and compact chrome.
///
/// Uses [CueLiftBrandAssets.markLight] (coral on transparent) so the mark sits
/// cleanly on light and dark surface app bars — not the navy-field launcher icon.
class CueLiftAppMark extends StatelessWidget {
  const CueLiftAppMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      CueLiftBrandAssets.markLight,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'CueLift',
    );
  }
}
