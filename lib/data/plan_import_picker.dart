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
