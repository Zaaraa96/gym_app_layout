import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../data/json_plan_importer.dart';
import '../../data/plan_import_picker.dart';
import '../../data/plan_package_format.dart';

export '../../data/plan_import_picker.dart';

/// Device document picker. Accepts `.gymplan`, `.zip`, and `.json`.
/// Android opens any file: DocumentsUI's MIME filter often hides adb-pushed
/// files, and we already reject unreadable bytes after the read.
class FilePickerPlanImportPicker implements PlanImportPicker {
  @override
  Future<PickedPlanFile?> pick() async {
    final onAndroid = Platform.isAndroid;
    final result = await FilePicker.platform.pickFiles(
      type: onAndroid ? FileType.any : FileType.custom,
      allowedExtensions: onAndroid
          ? null
          : const ['json', 'zip', PlanPackageFormat.extension],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    final path = file.path;
    final List<int> data;
    if (bytes != null && bytes.isNotEmpty) {
      data = bytes;
    } else if (path != null && path.isNotEmpty) {
      data = await File(path).readAsBytes();
    } else {
      throw const PlanImportException(
        'Could not read that file. Try another plan package or JSON file.',
      );
    }
    final name = file.name.trim().isEmpty ? 'plan.json' : file.name;
    return PickedPlanFile(fileName: name, bytes: data);
  }
}
