import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/widgets/app_text.dart';
import '../../data/models/models.dart';
import 'block_summary.dart';

/// Alternating day-preview row: icon, names × reps or duration, set badge.
class ExerciseBlockRow extends StatelessWidget {
  const ExerciseBlockRow({
    super.key,
    required this.block,
    required this.backgroundColor,
    required this.borderColor,
  });

  final ExerciseBlock block;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            _ExerciseIcon(path: blockSvgPath(block), size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final exercise in block.exercises)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Flexible(
                            child: AppText(exercise.title, style: dataTextStyle),
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            formatLoad(exercise),
                            style: dataTextStyle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _SetBadge(sets: blockSetCount(block)),
          ],
        ),
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge({required this.sets});

  final int sets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 55.0;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Center(
        child: AppText(
          '$sets',
          style: titleTextStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ExerciseIcon extends StatelessWidget {
  const _ExerciseIcon({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        placeholderBuilder: (_) => SizedBox(width: size, height: size),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}
