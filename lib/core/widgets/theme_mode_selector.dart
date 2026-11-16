import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';

/// System / Light / Dark switch.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key, this.compact = false});

  /// Icons only (for the sidebar).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: compact ? null : const Text('Auto'),
          tooltip: 'Follow the device setting',
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: compact ? null : const Text('Light'),
          tooltip: 'Light mode',
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: compact ? null : const Text('Dark'),
          tooltip: 'Dark mode',
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
    );
  }
}
