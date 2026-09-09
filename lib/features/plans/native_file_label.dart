/// Whether a native picker row label refers to [fileName] itself.
///
/// DocumentsUI often puts a size or type after the name, and long names can
/// wrap with a newline in the middle (`valid-plan.\ngymplan`). A raw substring
/// check is not enough: `plan.json` is contained in `invalid-plan.json`.
bool nativeFileLabelMatches(String? label, String fileName) {
  if (label == null || fileName.isEmpty) return false;
  final text = label.trim();
  if (_labelRefersToFile(text, fileName)) return true;
  // Wrap removes the characters between name parts; compare compacted forms.
  return _labelRefersToFile(_compactNativeLabel(text), _compactNativeLabel(fileName));
}

/// True only when the accessibility text is exactly [fileName] (after
/// collapsing DocumentsUI wrap whitespace).
bool nativeFileLabelIsExact(String? label, String fileName) {
  if (label == null || fileName.isEmpty) return false;
  final text = label.trim();
  if (text == fileName) return true;
  return _compactNativeLabel(text) == _compactNativeLabel(fileName);
}

bool _labelRefersToFile(String text, String fileName) {
  if (text.isEmpty || fileName.isEmpty) return false;
  if (text == fileName) return true;
  if (!text.startsWith(fileName) || text.length == fileName.length) {
    return text == fileName;
  }
  final next = String.fromCharCode(text.codeUnitAt(fileName.length));
  return !RegExp(r'[\w.-]').hasMatch(next);
}

String _compactNativeLabel(String label) => label.replaceAll(RegExp(r'\s+'), '');
