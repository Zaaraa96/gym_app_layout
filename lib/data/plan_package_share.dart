import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a built package to the OS (share sheet or save dialog).
abstract class PlanPackageShare {
  Future<bool> share({
    required String fileName,
    required List<int> bytes,
  });
}

class PlatformPlanPackageShare implements PlanPackageShare {
  @override
  Future<bool> share({
    required String fileName,
    required List<int> bytes,
  }) async {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(data, flush: true);
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip', name: fileName)],
      );
      return result.status != ShareResultStatus.dismissed;
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export plan',
      fileName: fileName,
      bytes: data,
      type: FileType.custom,
      allowedExtensions: ['gymplan', 'zip', 'json'],
    );
    if (path == null || path.isEmpty) return false;
    final out = File(path);
    if (!out.existsSync() || out.lengthSync() == 0) {
      await out.writeAsBytes(data, flush: true);
    }
    return true;
  }
}
