import 'dart:convert';
import 'dart:typed_data';

/// A plan package or JSON file the user chose from the device.
class PickedPlanFile {
  const PickedPlanFile({
    required this.fileName,
    this.contents,
    this.bytes,
  });

  final String fileName;
  final String? contents;
  final List<int>? bytes;

  List<int> get data {
    if (bytes != null && bytes!.isNotEmpty) return bytes!;
    if (contents != null) return utf8.encode(contents!);
    return const <int>[];
  }

  Uint8List get byteList => Uint8List.fromList(data);
}

/// Lets tests skip the platform file dialog.
abstract class PlanImportPicker {
  Future<PickedPlanFile?> pick();
}
