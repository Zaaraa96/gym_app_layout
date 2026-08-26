import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../data/json_plan_importer.dart';

/// A JSON file the user chose from the device.
class PickedPlanFile {
  const PickedPlanFile({required this.fileName, required this.contents});

  final String fileName;
  final String contents;
}

/// Lets tests skip the platform file dialog.
abstract class PlanImportPicker {
  Future<PickedPlanFile?> pick();
}

/// Device document picker restricted to `.json` files.
class FilePickerPlanImportPicker implements PlanImportPicker {
  @override
  Future<PickedPlanFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
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
