import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_item.dart';
import 'responsive_shell.dart';

/// The customer's tabs: Home, My bookings, Assistant, Profile.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      body: shell,
      bottomItems: customerNav,
      currentIndex: shell.currentIndex,
      onSelect: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
    );
  }
}
