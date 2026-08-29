import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/models/models.dart';
import 'exercise_asset_catalog.dart';
import 'exercise_media.dart';
import 'exercise_media_picker.dart';

/// Bottom sheet for choosing exercise preview media from assets, gallery, or URL.
Future<PickedExerciseMedia?> showExerciseMediaPickerSheet(
  BuildContext context, {
  PickedExerciseMedia? current,
  String titleHint = '',
}) {
  return showModalBottomSheet<PickedExerciseMedia>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ExerciseMediaPickerSheet(
      current: current,
      titleHint: titleHint,
    ),
  );
}

class ExerciseMediaPickerSheet extends StatefulWidget {
  const ExerciseMediaPickerSheet({
    super.key,
    this.current,
    this.titleHint = '',
  });

  final PickedExerciseMedia? current;
  final String titleHint;

  @override
  State<ExerciseMediaPickerSheet> createState() =>
      _ExerciseMediaPickerSheetState();
}

class _ExerciseMediaPickerSheetState extends State<ExerciseMediaPickerSheet> {
  late final TextEditingController _urlController;
  String? _error;
  late List<ExerciseAssetEntry> _assets;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.current?.source == ExerciseMediaSource.network
          ? widget.current!.uri
          : '',
    );
    _assets = suggestedAssetsForTitle(widget.titleHint);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _select(PickedExerciseMedia media) {
    Navigator.pop(context, media);
  }

  Future<void> _pickGalleryImage() async {
    final picker = ExerciseGalleryPickerScope.of(context);
    final picked = await picker.pickImage();
    if (!mounted || picked == null) return;
    _select(picked);
  }

  Future<void> _pickGalleryVideo() async {
    final picker = ExerciseGalleryPickerScope.of(context);
    final picked = await picker.pickVideo();
    if (!mounted || picked == null) return;
    _select(picked);
  }

  void _useNetworkUrl() {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter an image or video URL');
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _error = 'Enter a valid http or https URL');
      return;
    }
    _select(PickedExerciseMedia.network(raw));
  }

  bool _isSelected(ExerciseAssetEntry entry) {
    final current = widget.current;
    return current != null &&
        current.source == ExerciseMediaSource.asset &&
        current.uri == entry.assetPath;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Exercise preview', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Pick a bundled icon, photo from gallery, or image/video from the web.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _pickGalleryImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery photo'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _pickGalleryVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Gallery video'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Network URL',
                hintText: 'https://example.com/exercise.gif',
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip: 'Use URL',
                  onPressed: _useNetworkUrl,
                  icon: const Icon(Icons.link),
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _useNetworkUrl(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bundled exercises (${bundledExerciseAssets.length})',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _assets.length,
                itemBuilder: (context, index) {
                  final entry = _assets[index];
                  final selected = _isSelected(entry);
                  return InkWell(
                    key: Key('bundled-asset-${entry.id}'),
                    onTap: () => _select(PickedExerciseMedia.asset(entry.assetPath)),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _BundledAssetThumb(path: entry.assetPath, size: 36),
                          const SizedBox(height: 4),
                          Text(
                            entry.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BundledAssetThumb extends StatelessWidget {
  const _BundledAssetThumb({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: size, height: size);
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

/// Provides a testable gallery picker to descendant widgets.
class ExerciseGalleryPickerScope extends InheritedWidget {
  const ExerciseGalleryPickerScope({
    super.key,
    required this.picker,
    required super.child,
  });

  final ExerciseGalleryPicker picker;

  static ExerciseGalleryPicker of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExerciseGalleryPickerScope>();
    assert(scope != null, 'ExerciseGalleryPickerScope not found');
    return scope!.picker;
  }

  @override
  bool updateShouldNotify(ExerciseGalleryPickerScope oldWidget) =>
      picker != oldWidget.picker;
}
