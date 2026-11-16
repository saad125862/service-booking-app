import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/service.dart';
import 'service_image.dart';

/// Horizontal service card used in the main list.
class ServiceListTile extends StatelessWidget {
  const ServiceListTile({super.key, required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 116,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ServiceImage(url: service.imageUrl),
                  if (service.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: scheme.onPrimary),
                            const SizedBox(width: 2),
                            Text(
                              'Featured',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          Formatters.price(service.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.schedule, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            Formatters.duration(service.durationMinutes),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
