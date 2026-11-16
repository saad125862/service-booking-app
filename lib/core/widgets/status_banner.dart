import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BannerKind { error, success, info }

/// Inline message for form errors and confirmations.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, this.kind = BannerKind.error});

  final String message;
  final BannerKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (kind) {
      BannerKind.error => (scheme.errorContainer, scheme.onErrorContainer, Icons.error_outline),
      BannerKind.success => (
          AppColors.success.withValues(alpha: 0.14),
          const Color(0xFF1B6B2D),
          Icons.check_circle_outline,
        ),
      BannerKind.info => (scheme.secondaryContainer, scheme.onSecondaryContainer, Icons.info_outline),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: fg, height: 1.3))),
          ],
        ),
      ),
    );
  }
}
