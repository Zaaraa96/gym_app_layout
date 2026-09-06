/// Whether a native picker row label refers to [fileName] itself.
///
/// DocumentsUI often puts a size or type after the name. A substring check is
/// not enough: `plan.json` is contained in `invalid-plan.json`.
bool nativeFileLabelMatches(String? label, String fileName) {
  if (label == null || fileName.isEmpty) return false;
  final text = label.trim();
  if (text == fileName) return true;
  if (!text.startsWith(fileName) || text.length == fileName.length) {
    return text == fileName;
  }
  final next = String.fromCharCode(text.codeUnitAt(fileName.length));
  return !RegExp(r'[\w.-]').hasMatch(next);
}

/// True only when the accessibility text is exactly [fileName].
bool nativeFileLabelIsExact(String? label, String fileName) =>
    label != null && label.trim() == fileName;
