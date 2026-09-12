/// Normalized screen tap (0–1) for a DocumentsUI list row.
///
/// On the Patrol AVD a row tap selects the file ("1 selected"); the robot then
/// presses the top-bar **Select** to finish ACTION_OPEN_DOCUMENT. Aim at the
/// geometric middle of the row (title band), not the left icon strip.
({double x, double y}) documentsUiRowMiddleTap({
  required double rowMinX,
  required double rowMinY,
  required double rowMaxX,
  required double rowMaxY,
  required double screenWidth,
  required double screenHeight,
}) {
  final width = screenWidth <= 0 ? 1.0 : screenWidth;
  final height = screenHeight <= 0 ? 1.0 : screenHeight;
  final midX = (rowMinX + rowMaxX) / 2;
  final midY = (rowMinY + rowMaxY) / 2;
  return (
    x: (midX / width).clamp(0.01, 0.99),
    y: (midY / height).clamp(0.01, 0.99),
  );
}

/// Fallback when only the filename label is known: horizontal screen middle
/// at the label's vertical center (still avoids the left icon).
({double x, double y}) documentsUiLabelBandTap({
  required double labelCenterY,
  required double screenHeight,
}) {
  final height = screenHeight <= 0 ? 1.0 : screenHeight;
  return (
    x: 0.5,
    y: (labelCenterY / height).clamp(0.01, 0.99),
  );
}

/// True when [x] is in the left icon strip of a full-width DocumentsUI row.
/// Used by tests to assert open-taps never land on the selection control.
bool documentsUiTapIsLeftIconStrip({
  required double normalizedX,
  required double rowMinX,
  required double rowMaxX,
  required double screenWidth,
  double iconFraction = 0.18,
}) {
  final width = screenWidth <= 0 ? 1.0 : screenWidth;
  final rowWidth = (rowMaxX - rowMinX).abs();
  if (rowWidth <= 0) return false;
  final iconRight = (rowMinX + rowWidth * iconFraction) / width;
  return normalizedX < iconRight;
}
