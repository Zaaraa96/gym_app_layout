import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/app_theme.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';
import 'package:gym_app/features/catalog/catalog_media_thumbnail.dart';

Future<ui.Image> _capture(
  WidgetTester tester,
  GlobalKey key,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return boundary.toImage(pixelRatio: 2);
}

Future<void> _saveImage(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

/// True when RGBA bytes are a bright near-white (the old exercise media blast).
bool _isBrightWhiteBytes(int r, int g, int b, int a) {
  if (a < 200) return false;
  final minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
  final maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
  return minChannel >= 230 && (maxChannel - minChannel) <= 20;
}

Future<int> _countBrightWhite(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final data = bytes!.buffer.asUint8List();
  var count = 0;
  // Sample a grid — full scan is slow in widget tests.
  const step = 4;
  for (var y = 0; y < image.height; y += step) {
    for (var x = 0; x < image.width; x += step) {
      final i = (y * image.width + x) * 4;
      if (_isBrightWhiteBytes(data[i], data[i + 1], data[i + 2], data[i + 3])) {
        count++;
      }
    }
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bench press GIF sits on dark surface without white square',
      (tester) async {
    final entry =
        bundledExerciseAssets.firstWhere((e) => e.id == 'bench-press');
    final exercise = catalogExerciseFromAsset(entry);
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        home: Scaffold(
          backgroundColor: CueLiftColors.darkSurface,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: CatalogMediaThumbnail(
                exercise: exercise,
                size: 180,
                playGif: true,
                borderRadius: 16,
              ),
            ),
          ),
        ),
      ),
    );

    final image = await _capture(tester, key);
    await _saveImage(
      image,
      '/opt/cursor/artifacts/flutter_bench_gif_dark_surface.png',
    );

    final box = tester.getSize(find.byType(CatalogMediaThumbnail));
    expect(box.width, 180);
    expect(box.height, 180);

    final bright = await _countBrightWhite(image);
    // Transparent GIF on dark surface should not paint a white media square.
    expect(bright, lessThan(40),
        reason: 'expected near-zero bright-white samples, got $bright');
  });

  testWidgets('bench press PNG still sits on light surface', (tester) async {
    final entry =
        bundledExerciseAssets.firstWhere((e) => e.id == 'bench-press');
    final exercise = catalogExerciseFromAsset(entry);
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          backgroundColor: CueLiftColors.surface,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: CatalogMediaThumbnail(
                exercise: exercise,
                size: 180,
                playGif: false,
                borderRadius: 16,
              ),
            ),
          ),
        ),
      ),
    );

    final image = await _capture(tester, key);
    await _saveImage(
      image,
      '/opt/cursor/artifacts/flutter_bench_png_light_surface.png',
    );

    final box = tester.getSize(find.byType(CatalogMediaThumbnail));
    expect(box.width, 180);
    expect(box.height, 180);
  });
}
