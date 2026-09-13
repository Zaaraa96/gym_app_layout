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

final _documentsUiSelectedCount = RegExp(
  r'^\d+\s+selected$',
  caseSensitive: false,
);

/// True when DocumentsUI chrome shows selection mode ("1 selected").
bool documentsUiIsSelectionMode(Iterable<String?> labels) {
  for (final label in labels) {
    final text = label?.trim() ?? '';
    if (_documentsUiSelectedCount.hasMatch(text)) return true;
  }
  return false;
}

/// Candidate for the top-bar **Select** / **Open** confirm action.
class DocumentsUiConfirmCandidate {
  const DocumentsUiConfirmCandidate({
    required this.centerX,
    required this.centerY,
    this.text,
    this.contentDescription,
    this.resourceName,
  });

  final double centerX;
  final double centerY;
  final String? text;
  final String? contentDescription;
  final String? resourceName;
}

const _confirmLabels = {'select', 'open', 'done', 'ok'};

bool _isKnownSelectResource(String? resourceName) {
  final res = resourceName?.toLowerCase() ?? '';
  if (res.isEmpty) return false;
  // Exact menu ids only — do not use contains('select') (matches checkboxes /
  // "1 selected" chrome and taps the wrong node).
  return res.endsWith('/option_menu_select') ||
      res.endsWith('/action_menu_select') ||
      res.endsWith('/menu_select');
}

bool _hasConfirmLabel(DocumentsUiConfirmCandidate candidate) {
  final text = candidate.text?.trim().toLowerCase() ?? '';
  final desc = candidate.contentDescription?.trim().toLowerCase() ?? '';
  return _confirmLabels.contains(text) || _confirmLabels.contains(desc);
}

/// Pick the top-bar Select/Open control from native candidates.
///
/// Prefers exact "Select" text in the upper action-bar band. Ignores broad
/// resource names that merely contain "select".
DocumentsUiConfirmCandidate? documentsUiPickConfirmAction(
  Iterable<DocumentsUiConfirmCandidate> candidates, {
  required double screenHeight,
}) {
  final height = screenHeight <= 0 ? 1.0 : screenHeight;
  final actionBarMaxY = height * 0.22;
  final matches = candidates
      .where(
        (c) =>
            (_hasConfirmLabel(c) || _isKnownSelectResource(c.resourceName)) &&
            c.centerY <= actionBarMaxY,
      )
      .toList();
  if (matches.isEmpty) return null;

  int rank(DocumentsUiConfirmCandidate c) {
    final text = c.text?.trim().toLowerCase() ?? '';
    if (text == 'select') return 0;
    if (text == 'open') return 1;
    if (_isKnownSelectResource(c.resourceName)) return 2;
    return 3;
  }

  matches.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    return a.centerY.compareTo(b.centerY);
  });
  return matches.first;
}

/// Coordinate fallbacks for the DocumentsUI top-bar **Select** (left of ⋮).
List<({double x, double y})> documentsUiSelectButtonFallbackTaps() => const [
      (x: 0.78, y: 0.08),
      (x: 0.85, y: 0.08),
      (x: 0.82, y: 0.09),
      (x: 0.75, y: 0.07),
    ];
