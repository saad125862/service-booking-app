import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with a neutral placeholder and a fallback icon on failure.
class ServiceImage extends StatelessWidget {
  const ServiceImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.spa_outlined, color: scheme.onPrimaryContainer, size: 32),
    );

    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => Container(color: scheme.surfaceContainerHighest),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
