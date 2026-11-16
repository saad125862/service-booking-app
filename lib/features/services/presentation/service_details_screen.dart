import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/service.dart';
import 'services_providers.dart';
import 'widgets/service_image.dart';

/// Full details for one service with a "Book now" action.
/// [initial] (from the list) is shown instantly while fresh data loads.
class ServiceDetailsScreen extends ConsumerWidget {
  const ServiceDetailsScreen({super.key, required this.serviceId, this.initial});

  final String serviceId;
  final Service? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(serviceDetailProvider(serviceId));
    final service = detail.value ?? initial;

    if (service == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detail.hasError
            ? ErrorView(
                message: detail.error is ApiException ? (detail.error as ApiException).message : 'Please try again.',
                onRetry: () => ref.invalidate(serviceDetailProvider(serviceId)),
              )
            : const LoadingView(),
      );
    }

    return _DetailsView(service: service);
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: scheme.surface.withValues(alpha: 0.85),
                    child: IconButton(
                      tooltip: 'Back',
                      icon: Icon(Icons.arrow_back, color: scheme.onSurface),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(background: Hero(tag: 'service-img-${service.id}', child: ServiceImage(url: service.imageUrl))),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(service.category),
                            backgroundColor: scheme.primaryContainer,
                            side: BorderSide.none,
                            labelStyle: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                          ),
                          if (service.isFeatured)
                            Chip(
                              avatar: Icon(Icons.star_rounded, size: 18, color: scheme.onTertiaryContainer),
                              label: const Text('Featured'),
                              backgroundColor: scheme.tertiaryContainer,
                              side: BorderSide.none,
                              labelStyle: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        service.name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.payments_outlined,
                              label: 'Price',
                              value: Formatters.price(service.price),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.schedule,
                              label: 'Duration',
                              value: Formatters.duration(service.durationMinutes),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.event_available_outlined,
                              label: 'Booked',
                              value: service.bookingsCount == 1 ? '1 time' : '${service.bookingsCount} times',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'About this service',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.description,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: scheme.onSurfaceVariant),
                      ),
                      if (service.attributes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Good to know', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        for (final a in service.attributes)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: a.isLong
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.label,
                                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        a.display,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.4,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          a.label,
                                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          a.display,
                                          textAlign: TextAlign.end,
                                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(
                        Formatters.price(service.price),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AppButton(
                      label: 'Book now',
                      icon: Icons.event_available,
                      onPressed: () => context.push('/service/${service.id}/book', extra: service),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
