import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/new_id.dart' as ids;

/// Copies imported user media into the app documents folder.
class ExerciseMediaStore {
  ExerciseMediaStore({
    this.documentsPath,
    String Function()? makeId,
  }) : newId = makeId ?? ids.newId;

  /// When set, files go here instead of the platform documents directory.
  final String? documentsPath;
  final String Function() newId;

  Future<String> persistBytes(List<int> bytes, String extension) async {
    final root = documentsPath ?? (await getApplicationDocumentsDirectory()).path;
    final mediaDir = Directory(p.join(root, 'exercise_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    var ext = extension.trim();
    if (ext.isNotEmpty && !ext.startsWith('.')) ext = '.$ext';
    final dest = p.join(mediaDir.path, '${newId()}$ext');
    await File(dest).writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return dest;
  }

  Future<String> persistFile(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    return persistBytes(bytes, p.extension(sourcePath));
  }
}
