import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shell/nav_item.dart';
import '../../shell/responsive_shell.dart';

/// The admin's area: a sidebar with every admin screen, and on phones a bottom bar with the
/// everyday ones plus "More" (which opens the sidebar).
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // Branches beyond the first four (reports, payments, fields, profile) live under "More".
    final selected = shell.currentIndex < adminMoreIndex ? shell.currentIndex : adminMoreIndex;
    return ResponsiveShell(
      body: shell,
      bottomItems: adminBottomNav,
      currentIndex: selected,
      menuIndex: adminMoreIndex,
      onSelect: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
    );
  }
}
