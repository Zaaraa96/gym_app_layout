import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../data/json_plan_importer.dart';
import '../../data/plan_import_picker.dart';

export '../../data/plan_import_picker.dart';

/// Device document picker. iOS / desktop filter to `.json`. Android opens any
/// file: DocumentsUI's JSON MIME filter often hides adb-pushed or unindexed
/// `.json` files, and we already reject non-JSON after the read.
class FilePickerPlanImportPicker implements PlanImportPicker {
  @override
  Future<PickedPlanFile?> pick() async {
    final onAndroid = Platform.isAndroid;
    final result = await FilePicker.platform.pickFiles(
      type: onAndroid ? FileType.any : FileType.custom,
      allowedExtensions: onAndroid ? null : const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;
    final String contents;
    if (bytes != null && bytes.isNotEmpty) {
      contents = utf8.decode(bytes);
    } else if (path != null && path.isNotEmpty) {
      contents = await File(path).readAsString();
    } else {
      throw const PlanImportException(
        'Could not read that file. Try another JSON file.',
      );
    }
    final name = file.name.trim().isEmpty ? 'plan.json' : file.name;
    return PickedPlanFile(fileName: name, contents: contents);
  }
}
