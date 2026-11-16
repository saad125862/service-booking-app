import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/service_filters.dart';
import '../services_providers.dart';

/// Opens the sort + price filter bottom sheet.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ServiceSort _sort;
  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    final f = ref.read(serviceFiltersProvider);
    _sort = f.sort;
    _range = RangeValues(f.minPrice ?? 0, f.maxPrice ?? kPriceFilterCeiling);
  }

  void _apply() {
    ref.read(serviceFiltersProvider.notifier).apply(
          sort: _sort,
          minPrice: _range.start > 0 ? _range.start : null,
          maxPrice: _range.end < kPriceFilterCeiling ? _range.end : null,
        );
    Navigator.of(context).pop();
  }

  void _reset() => setState(() {
        _sort = ServiceSort.featured;
        _range = const RangeValues(0, kPriceFilterCeiling);
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endLabel = _range.end >= kPriceFilterCeiling
        ? '${Formatters.price(kPriceFilterCeiling)}+'
        : Formatters.price(_range.end);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Sort and filter', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 12),
              Text('Sort by', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in ServiceSort.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _sort == s,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _sort = s),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Price range', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    '${Formatters.price(_range.start)} - $endLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              RangeSlider(
                values: _range,
                min: 0,
                max: kPriceFilterCeiling,
                divisions: 40,
                labels: RangeLabels(Formatters.price(_range.start), endLabel),
                onChanged: (v) => setState(() => _range = v),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _apply, child: const Text('Show results')),
            ],
          ),
        ),
      ),
    );
  }
}
