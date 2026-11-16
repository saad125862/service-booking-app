import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services_providers.dart';

/// Horizontally scrolling category filter ("All" + one chip per category).
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(serviceFiltersProvider.select((f) => f.category));
    final notifier = ref.read(serviceFiltersProvider.notifier);

    // The chips are a convenience: if categories fail to load, hide the row quietly.
    final names = categories.value?.map((c) => c.name).toList() ?? const <String>[];
    if (names.isEmpty) return const SizedBox(height: 4);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: names.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = i == 0 ? 'All' : names[i - 1];
          final isSelected = i == 0 ? selected == null : selected == label;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => notifier.setCategory(i == 0 ? null : label),
          );
        },
      ),
    );
  }
}
