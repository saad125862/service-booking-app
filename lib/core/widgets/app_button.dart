import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// Primary / secondary button with a built-in loading state, a small press-down effect
/// and a light haptic tap.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;

    final child = AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: Curves.easeOut,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: c),
      ),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: outlined ? scheme.primary : scheme.onPrimary),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    void tap() {
      HapticFeedback.lightImpact();
      onPressed!();
    }

    return PressScale(
      enabled: enabled,
      child: outlined
          ? OutlinedButton(onPressed: enabled ? tap : null, child: child)
          : FilledButton(onPressed: enabled ? tap : null, child: child),
    );
  }
}
