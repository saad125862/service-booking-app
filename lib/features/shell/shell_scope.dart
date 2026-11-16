import 'package:flutter/material.dart';

/// Lets screens inside a shell open its drawer and know whether the sidebar is permanent.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.openDrawer, required this.isWide, required super.child});

  final VoidCallback openDrawer;

  /// Wide screens (tablet, web) show a permanent sidebar instead of a drawer.
  final bool isWide;

  static ShellScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => oldWidget.isWide != isWide;
}

/// AppBar `leading` for screens inside a shell: a menu button on phones that opens the
/// sidebar drawer, nothing on wide screens (the sidebar is always visible there).
Widget? shellMenuLeading(BuildContext context) {
  final scope = ShellScope.maybeOf(context);
  if (scope == null || scope.isWide) return null;
  return IconButton(tooltip: 'Menu', icon: const Icon(Icons.menu), onPressed: scope.openDrawer);
}
