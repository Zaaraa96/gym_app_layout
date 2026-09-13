import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/plans/documents_ui_row_tap.dart';

void main() {
  // Pixel-ish portrait list: full-width row with icon | title | preview.
  const screenW = 1080.0;
  const screenH = 2400.0;
  const rowMinX = 0.0;
  const rowMaxX = 1080.0;
  const rowMinY = 600.0;
  const rowMaxY = 760.0;

  test('middle tap is geometric center of the row', () {
    final tap = documentsUiRowMiddleTap(
      rowMinX: rowMinX,
      rowMinY: rowMinY,
      rowMaxX: rowMaxX,
      rowMaxY: rowMaxY,
      screenWidth: screenW,
      screenHeight: screenH,
    );
    expect(tap.x, closeTo(0.5, 0.001));
    expect(tap.y, closeTo((600 + 760) / 2 / screenH, 0.001));
  });

  test('middle tap is not in the left icon strip', () {
    final tap = documentsUiRowMiddleTap(
      rowMinX: rowMinX,
      rowMinY: rowMinY,
      rowMaxX: rowMaxX,
      rowMaxY: rowMaxY,
      screenWidth: screenW,
      screenHeight: screenH,
    );
    expect(
      documentsUiTapIsLeftIconStrip(
        normalizedX: tap.x,
        rowMinX: rowMinX,
        rowMaxX: rowMaxX,
        screenWidth: screenW,
      ),
      isFalse,
    );
  });

  test('legacy icon tap (label.minX - 48) is in the left icon strip', () {
    // Filename label starts after the icon, around x=160 on a 1080-wide phone.
    const labelMinX = 160.0;
    final legacyIconX = (labelMinX - 48) / screenW;
    expect(
      documentsUiTapIsLeftIconStrip(
        normalizedX: legacyIconX,
        rowMinX: rowMinX,
        rowMaxX: rowMaxX,
        screenWidth: screenW,
      ),
      isTrue,
    );
  });

  test('label-band fallback uses screen-center X', () {
    final tap = documentsUiLabelBandTap(
      labelCenterY: 680,
      screenHeight: screenH,
    );
    expect(tap.x, 0.5);
    expect(tap.y, closeTo(680 / screenH, 0.001));
  });

  test('selection mode matches "N selected" chrome', () {
    expect(documentsUiIsSelectionMode(['1 selected']), isTrue);
    expect(documentsUiIsSelectionMode(['3 selected', 'broken.json']), isTrue);
    expect(
      documentsUiIsSelectionMode(['Recent files', 'broken.json']),
      isFalse,
    );
    expect(documentsUiIsSelectionMode([null, '']), isFalse);
  });

  test('pick confirm prefers Select text in the action bar', () {
    final picked = documentsUiPickConfirmAction(
      const [
        DocumentsUiConfirmCandidate(
          centerX: 100,
          centerY: 900,
          text: 'Select', // too low — list chrome, ignore
        ),
        DocumentsUiConfirmCandidate(
          centerX: 200,
          centerY: 120,
          resourceName: 'com.google.android.documentsui:id/icon_selected',
        ),
        DocumentsUiConfirmCandidate(
          centerX: 900,
          centerY: 160,
          text: 'Select',
        ),
        DocumentsUiConfirmCandidate(
          centerX: 800,
          centerY: 160,
          text: 'Open',
        ),
      ],
      screenHeight: screenH,
    );
    expect(picked?.text, 'Select');
    expect(picked?.centerX, 900);
  });

  test('pick confirm ignores resourceName.contains(select) checkboxes', () {
    final picked = documentsUiPickConfirmAction(
      const [
        DocumentsUiConfirmCandidate(
          centerX: 80,
          centerY: 140,
          resourceName: 'com.google.android.documentsui:id/icon_selected',
        ),
        DocumentsUiConfirmCandidate(
          centerX: 900,
          centerY: 150,
          resourceName:
              'com.google.android.documentsui:id/option_menu_select',
        ),
      ],
      screenHeight: screenH,
    );
    expect(
      picked?.resourceName,
      'com.google.android.documentsui:id/option_menu_select',
    );
  });

  test('Select fallback taps stay in the top-right action bar', () {
    final taps = documentsUiSelectButtonFallbackTaps();
    expect(taps, isNotEmpty);
    for (final tap in taps) {
      expect(tap.x, greaterThan(0.7));
      expect(tap.x, lessThan(0.95));
      expect(tap.y, greaterThan(0.05));
      expect(tap.y, lessThan(0.12));
    }
  });
}
