import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/common/exercise_asset_catalog.dart';

bool _isBrightWhite(int r, int g, int b, int a) {
  if (a < 200) return false;
  final minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
  final maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
  return minChannel >= 230 && (maxChannel - minChannel) <= 22;
}

Future<int> _countBrightWhite(ui.Image image, {int step = 2}) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final data = bytes!.buffer.asUint8List();
  var count = 0;
  for (var y = 0; y < image.height; y += step) {
    for (var x = 0; x < image.width; x += step) {
      final i = (y * image.width + x) * 4;
      if (_isBrightWhite(data[i], data[i + 1], data[i + 2], data[i + 3])) {
        count++;
      }
    }
  }
  return count;
}

Future<void> _saveImage(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

Future<void> _assertAssetHasNoWhiteCanvas(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  expect(codec.frameCount, greaterThanOrEqualTo(1));

  for (var i = 0; i < codec.frameCount; i++) {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final px = bytes!.buffer.asUint8List();
    expect(px[3], lessThan(16), reason: '$assetPath frame $i corner alpha');
    final bright = await _countBrightWhite(image);
    expect(
      bright,
      lessThan(20),
      reason: '$assetPath frame $i has $bright bright-white samples',
    );
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bench-press GIF frames have transparent corners (no white canvas)',
      () async {
    final data = await rootBundle.load(
      'assets/image/exercises/gifs/bench-press.gif',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    expect(codec.frameCount, greaterThanOrEqualTo(2));

    for (var i = 0; i < codec.frameCount; i++) {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final bytes =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final px = bytes!.buffer.asUint8List();
      expect(px[3], lessThan(16), reason: 'frame $i corner alpha');
      final bright = await _countBrightWhite(image);
      expect(
        bright,
        lessThan(20),
        reason: 'frame $i still has $bright bright-white samples',
      );
      if (i <= 1) {
        await _saveImage(
          image,
          '/opt/cursor/artifacts/decoded_bench_gif_frame_$i.png',
        );
      }
      image.dispose();
    }
  });

  test('bench-press PNG has transparent canvas', () async {
    await _assertAssetHasNoWhiteCanvas(
      'assets/image/exercises/bench-press.png',
    );
    final data = await rootBundle.load('assets/image/exercises/bench-press.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    await _saveImage(
      frame.image,
      '/opt/cursor/artifacts/decoded_bench_png.png',
    );
    frame.image.dispose();
  });

  test('all bundled exercise stills/gifs punch out white backgrounds', () async {
    for (final entry in bundledExerciseAssets) {
      await _assertAssetHasNoWhiteCanvas(entry.assetPath);
      final gif = entry.gifPath;
      if (gif.isNotEmpty) {
        await _assertAssetHasNoWhiteCanvas(gif);
      }
    }
  });
}
