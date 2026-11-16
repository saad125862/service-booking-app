import 'package:flutter/material.dart';

import 'app_button.dart';
import 'motion.dart';

/// Loading state: soft shimmering placeholder rows that fill the space (instead of a lone spinner),
/// so the screen already looks like what is about to appear. [message] is read by screen readers.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      child: LayoutBuilder(
        builder: (context, c) {
          const rowHeight = 104.0; // a row plus its gap
          final rows = c.hasBoundedHeight ? ((c.maxHeight - 16) / rowHeight).floor().clamp(0, 6) : 4;
          if (rows == 0) {
            return const Center(
              child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ExcludeSemantics(
                child: Shimmer(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < rows; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Reveal(index: i, dy: 8, child: const SkeletonRow()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Friendly empty state, optionally with an action.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) =>
      _MessageView(icon: icon, title: title, message: message, actionLabel: actionLabel, onAction: onAction);
}

/// Error state with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry, this.title = 'Something went wrong'});

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _MessageView(
    icon: Icons.cloud_off_outlined,
    title: title,
    message: message,
    actionLabel: onRetry == null ? null : 'Try again',
    onAction: onRetry,
    isError: true,
  );
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isError ? scheme.errorContainer : scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: AppButton(label: actionLabel!, onPressed: onAction, outlined: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
