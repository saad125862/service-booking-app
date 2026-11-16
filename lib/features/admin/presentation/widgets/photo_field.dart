import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_picker.dart';

/// What the admin chose for a service's photo, shown in [PhotoField].
class PhotoChoice {
  const PhotoChoice({this.picked, this.url});

  /// A photo chosen from the device (uploaded when the service is saved).
  final PickedImage? picked;

  /// The photo the service already has.
  final String? url;

  bool get hasPhoto => picked != null || (url != null && url!.isNotEmpty);
}

/// Photo section of the service form: a preview and a button that opens the file picker
/// (instead of typing a link). The photo is uploaded when the service is saved.
class PhotoField extends ConsumerStatefulWidget {
  const PhotoField({super.key, required this.choice, required this.onChanged, this.enabled = true});

  final PhotoChoice choice;
  final ValueChanged<PhotoChoice> onChanged;
  final bool enabled;

  @override
  ConsumerState<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends ConsumerState<PhotoField> {
  String? _error;
  bool _picking = false;

  Future<void> _choose() async {
    setState(() {
      _error = null;
      _picking = true;
    });
    try {
      final picked = await ref.read(imagePickerProvider)();
      if (picked != null) widget.onChanged(PhotoChoice(picked: picked));
    } on ImageProblem catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't open your photos. Please try again.");
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final choice = widget.choice;

    final Widget preview;
    if (choice.picked != null) {
      preview = Image.memory(choice.picked!.bytes, fit: BoxFit.cover, width: double.infinity);
    } else if (choice.url != null && choice.url!.isNotEmpty) {
      preview = Image.network(
        choice.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _Empty(label: "Can't show this photo"),
      );
    } else {
      preview = const _Empty(label: 'No photo yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Photo (optional)', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 170, child: preview),
          ),
        ),
        if (choice.picked != null) ...[
          const SizedBox(height: 6),
          Text(
            '${choice.picked!.name} · ${choice.picked!.sizeLabel} · uploads when you save',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: widget.enabled && !_picking ? _choose : null,
                icon: _picking
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.photo_library_outlined),
                label: Text(choice.hasPhoto ? 'Change photo' : 'Choose photo'),
              ),
            ),
            if (choice.hasPhoto) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Remove photo',
                onPressed: widget.enabled ? () => widget.onChanged(const PhotoChoice()) : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: scheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
