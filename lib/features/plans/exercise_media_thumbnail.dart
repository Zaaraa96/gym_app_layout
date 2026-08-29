import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/models/models.dart';
import 'exercise_media.dart';

/// Renders a block's preview media from assets, gallery, or network.
class ExerciseMediaThumbnail extends StatelessWidget {
  const ExerciseMediaThumbnail({
    super.key,
    required this.block,
    this.size = 40,
    this.borderRadius = 8,
  });

  final ExerciseBlock block;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final media = resolveBlockMedia(block);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _MediaBody(media: media),
      ),
    );
  }
}

class _MediaBody extends StatelessWidget {
  const _MediaBody({required this.media});

  final ExerciseMediaRef media;

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      return _VideoPlaceholder();
    }

    if (media.kind == ExerciseMediaKind.svg) {
      if (media.source == ExerciseMediaSource.asset) {
        return SvgPicture.asset(
          media.uri,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _fallback(context),
        );
      }
      return _fallback(context);
    }

    if (media.source == ExerciseMediaSource.asset) {
      return Image.asset(
        media.uri,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (media.source == ExerciseMediaSource.gallery) {
      return Image.file(
        File(media.uri),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return Image.network(
      media.uri,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.fitness_center,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Icon(
            Icons.videocam_outlined,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.play_circle_fill,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
