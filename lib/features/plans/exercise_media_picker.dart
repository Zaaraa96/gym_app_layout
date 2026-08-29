import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/models.dart';
import '../../data/new_id.dart';
import 'exercise_media.dart';

/// Result of choosing preview media for an exercise block.
class PickedExerciseMedia {
  const PickedExerciseMedia({
    required this.uri,
    required this.source,
    required this.kind,
  });

  final String uri;
  final ExerciseMediaSource source;
  final ExerciseMediaKind kind;

  factory PickedExerciseMedia.asset(String assetPath) {
    return PickedExerciseMedia(
      uri: assetPath,
      source: ExerciseMediaSource.asset,
      kind: kindForPath(assetPath),
    );
  }

  factory PickedExerciseMedia.network(String url) {
    return PickedExerciseMedia(
      uri: url,
      source: ExerciseMediaSource.network,
      kind: kindForNetworkUrl(url),
    );
  }

  factory PickedExerciseMedia.galleryFile({
    required String uri,
    required ExerciseMediaKind kind,
  }) {
    return PickedExerciseMedia(
      uri: uri,
      source: ExerciseMediaSource.gallery,
      kind: kind,
    );
  }

  void applyTo(ExerciseBlock block) {
    block.mediaUri = uri;
    block.mediaSource = source;
    block.mediaKind = kind;
    if (source == ExerciseMediaSource.asset && kind == ExerciseMediaKind.svg) {
      block.svgPath = uri;
    } else {
      block.svgPath = null;
    }
  }

  void clearFrom(ExerciseBlock block) => PickedExerciseMedia.clearBlock(block);

  static void clearBlock(ExerciseBlock block) {
    block.mediaUri = null;
    block.mediaSource = ExerciseMediaSource.none;
    block.mediaKind = ExerciseMediaKind.unknown;
    block.svgPath = null;
  }

  static PickedExerciseMedia? fromBlock(ExerciseBlock block) {
    final uri = block.mediaUri?.trim();
    final source = block.mediaSource;
    final kind = block.mediaKind;
    if (uri != null &&
        uri.isNotEmpty &&
        source != ExerciseMediaSource.none &&
        kind != ExerciseMediaKind.unknown) {
      return PickedExerciseMedia(uri: uri, source: source, kind: kind);
    }
    final legacy = block.svgPath?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      return PickedExerciseMedia.asset(legacy);
    }
    return null;
  }
}

/// Lets tests stub gallery and camera picks.
abstract class ExerciseGalleryPicker {
  Future<PickedExerciseMedia?> pickImage();
  Future<PickedExerciseMedia?> pickVideo();
}

class ImagePickerExerciseGalleryPicker implements ExerciseGalleryPicker {
  ImagePickerExerciseGalleryPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedExerciseMedia?> pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final stored = await _persistPickedFile(file.path);
    return PickedExerciseMedia.galleryFile(
      uri: stored,
      kind: kindForPath(stored),
    );
  }

  @override
  Future<PickedExerciseMedia?> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    final stored = await _persistPickedFile(file.path);
    return PickedExerciseMedia.galleryFile(
      uri: stored,
      kind: ExerciseMediaKind.video,
    );
  }
}

Future<String> _persistPickedFile(String sourcePath) async {
  final docs = await getApplicationDocumentsDirectory();
  final mediaDir = Directory(p.join(docs.path, 'exercise_media'));
  if (!await mediaDir.exists()) {
    await mediaDir.create(recursive: true);
  }
  final ext = p.extension(sourcePath);
  final dest = p.join(mediaDir.path, '${newId()}$ext');
  await File(sourcePath).copy(dest);
  return dest;
}
