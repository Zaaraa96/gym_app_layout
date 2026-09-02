import '../../domain/models/models.dart';
import 'exercise_asset_catalog.dart';

/// Resolved preview media for an [ExerciseBlock].
class ExerciseMediaRef {
  const ExerciseMediaRef({
    required this.uri,
    required this.source,
    required this.kind,
  });

  final String uri;
  final ExerciseMediaSource source;
  final ExerciseMediaKind kind;

  bool get isSvg => kind == ExerciseMediaKind.svg;
  bool get isVideo => kind == ExerciseMediaKind.video;
  bool get isNetwork => source == ExerciseMediaSource.network;
  bool get isLocalFile =>
      source == ExerciseMediaSource.gallery && !uri.startsWith('http');
}

/// Fallback icon when a block has no media configured.
const defaultBlockSvg = 'assets/image/upper-body.svg';

ExerciseMediaRef resolveBlockMedia(ExerciseBlock block) {
  final uri = block.mediaUri?.trim();
  final source = block.mediaSource;
  final kind = block.mediaKind;
  if (uri != null &&
      uri.isNotEmpty &&
      source != ExerciseMediaSource.none &&
      kind != ExerciseMediaKind.unknown) {
    return ExerciseMediaRef(uri: uri, source: source, kind: kind);
  }

  final legacy = block.svgPath?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    return ExerciseMediaRef(
      uri: legacy,
      source: ExerciseMediaSource.asset,
      kind: kindForPath(legacy),
    );
  }

  final title = block.exercises.isEmpty ? null : block.exercises.first.title;
  final matched = matchExerciseAsset(title);
  if (matched != null) {
    return ExerciseMediaRef(
      uri: matched.assetPath,
      source: ExerciseMediaSource.asset,
      kind: kindForPath(matched.assetPath),
    );
  }

  return const ExerciseMediaRef(
    uri: defaultBlockSvg,
    source: ExerciseMediaSource.asset,
    kind: ExerciseMediaKind.svg,
  );
}

ExerciseMediaRef assetMediaRef(String assetPath) {
  final lower = assetPath.toLowerCase();
  final kind = lower.endsWith('.svg')
      ? ExerciseMediaKind.svg
      : lower.endsWith('.gif')
          ? ExerciseMediaKind.gif
          : ExerciseMediaKind.image;
  return ExerciseMediaRef(
    uri: assetPath,
    source: ExerciseMediaSource.asset,
    kind: kind,
  );
}

ExerciseMediaKind kindForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.svg')) return ExerciseMediaKind.svg;
  if (lower.endsWith('.gif')) return ExerciseMediaKind.gif;
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv')) {
    return ExerciseMediaKind.video;
  }
  return ExerciseMediaKind.image;
}

ExerciseMediaKind kindForNetworkUrl(String url) {
  final withoutQuery = url.split('?').first.toLowerCase();
  return kindForPath(withoutQuery);
}

ExerciseAssetEntry? selectedBundledAsset(ExerciseBlock block) {
  final media = resolveBlockMedia(block);
  if (media.source != ExerciseMediaSource.asset) return null;
  return bundledAssetByPath(media.uri);
}
