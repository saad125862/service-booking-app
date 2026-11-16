import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/service.dart';
import 'service_image.dart';

/// Larger vertical card for the featured carousel.
class FeaturedServiceCard extends StatelessWidget {
  const FeaturedServiceCard({super.key, required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SizedBox(width: double.infinity, child: ServiceImage(url: service.imageUrl))),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Formatters.price(service.price),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          Formatters.duration(service.durationMinutes),
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
