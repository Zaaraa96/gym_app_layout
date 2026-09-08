import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../domain/models/catalog_exercise.dart';
import '../../domain/models/enums.dart';

/// Still or looping GIF for a catalog movement.
class CatalogMediaThumbnail extends StatelessWidget {
  const CatalogMediaThumbnail({
    super.key,
    required this.exercise,
    this.size = 48,
    this.playGif = false,
    this.borderRadius = 8,
  });

  final CatalogExercise exercise;
  final double size;
  final bool playGif;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final gif = exercise.gifPath?.trim();
    final useGif = playGif && gif != null && gif.isNotEmpty;
    final uri = useGif ? gif : exercise.mediaUri;
    final kind = useGif ? ExerciseMediaKind.gif : exercise.mediaKind;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _body(context, uri, kind, exercise.mediaSource),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    String uri,
    ExerciseMediaKind kind,
    ExerciseMediaSource source,
  ) {
    if (kind == ExerciseMediaKind.video) {
      return _fallback(context, icon: Icons.videocam_outlined);
    }
    if (kind == ExerciseMediaKind.svg && source == ExerciseMediaSource.asset) {
      return SvgPicture.asset(
        uri,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _fallback(context),
      );
    }
    if (source == ExerciseMediaSource.asset) {
      return Image.asset(
        uri,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    if (source == ExerciseMediaSource.gallery) {
      return Image.file(
        File(uri),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    if (source == ExerciseMediaSource.network) {
      return Image.network(
        uri,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context, {IconData icon = Icons.fitness_center}) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        icon,
        size: size * 0.45,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
