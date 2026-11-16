import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'nav_item.dart';
import 'shell_scope.dart';

/// Phones: bottom navigation plus a left drawer (sidebar). Wide screens: a permanent sidebar.
/// Used by both the customer and the admin shells.
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({
    super.key,
    required this.body,
    required this.bottomItems,
    required this.currentIndex,
    required this.onSelect,
  });

  final Widget body;

  /// The main destinations shown in the bottom bar on phones.
  final List<NavItem> bottomItems;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Width from which the permanent sidebar replaces the drawer.
  static const wideBreakpoint = 840.0;

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= ResponsiveShell.wideBreakpoint;

    if (wide) {
      return ShellScope(
        openDrawer: () {},
        isWide: true,
        child: Scaffold(
          body: Row(
            children: [
              const SizedBox(width: 280, child: AppSidebar()),
              const VerticalDivider(width: 1),
              Expanded(child: widget.body),
            ],
          ),
        ),
      );
    }

    return ShellScope(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      isWide: false,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const Drawer(child: AppSidebar(inDrawer: true)),
        body: widget.body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.currentIndex,
          onDestinationSelected: widget.onSelect,
          destinations: [
            for (final d in widget.bottomItems)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
          ],
        ),
      ),
    );
  }
}
