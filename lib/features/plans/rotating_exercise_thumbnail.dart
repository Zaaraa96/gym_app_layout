import 'dart:async';

import 'package:flutter/material.dart';

import 'day_card_summary.dart';
import 'exercise_media.dart';
import 'exercise_media_thumbnail.dart';

/// Cycles catalog/stored stills on a day card. A single asset stays still.
///
/// Auto-advance pauses while another route covers this one so
/// `pumpAndSettle` on editors above [PlanPage] can finish.
class RotatingExerciseThumbnail extends StatefulWidget {
  const RotatingExerciseThumbnail({
    super.key,
    required this.media,
    this.size = 88,
    this.interval = dayCardThumbnailInterval,
  });

  final List<ExerciseMediaRef> media;
  final double size;
  final Duration interval;

  @override
  State<RotatingExerciseThumbnail> createState() =>
      _RotatingExerciseThumbnailState();
}

class _RotatingExerciseThumbnailState extends State<RotatingExerciseThumbnail> {
  var _index = 0;
  Timer? _timer;
  Animation<double>? _secondary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context)?.secondaryAnimation;
    if (!identical(next, _secondary)) {
      _secondary?.removeStatusListener(_onCovered);
      _secondary = next;
      _secondary?.addStatusListener(_onCovered);
    }
    _syncTimer();
  }

  @override
  void didUpdateWidget(RotatingExerciseThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameUris(oldWidget.media, widget.media)) {
      _index = 0;
    }
    _syncTimer();
  }

  @override
  void dispose() {
    _secondary?.removeStatusListener(_onCovered);
    _timer?.cancel();
    super.dispose();
  }

  void _onCovered(AnimationStatus status) {
    if (!mounted) return;
    _syncTimer();
  }

  void _syncTimer() {
    final want = _shouldAdvance;
    if (want) {
      _timer ??= Timer.periodic(widget.interval, (_) {
        if (!mounted || widget.media.length < 2) return;
        setState(() => _index = (_index + 1) % widget.media.length);
      });
      return;
    }
    _timer?.cancel();
    _timer = null;
  }

  bool get _shouldAdvance {
    if (widget.media.length < 2) return false;
    if (widget.interval == Duration.zero) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();
    final item = widget.media[_index % widget.media.length];
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: ExerciseMediaThumbnail.media(
          key: ValueKey(item.uri),
          media: item,
          size: widget.size,
          borderRadius: 16,
        ),
      ),
    );
  }
}

bool _sameUris(List<ExerciseMediaRef> a, List<ExerciseMediaRef> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].uri != b[i].uri) return false;
  }
  return true;
}
