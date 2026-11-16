import 'package:flutter/material.dart';

import '../auth/domain/user.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.selectedIcon, this.location);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String location;
}

const customerNav = [
  NavItem('Home', Icons.home_outlined, Icons.home, '/'),
  NavItem('My bookings', Icons.calendar_month_outlined, Icons.calendar_month, '/bookings'),
  NavItem('Assistant', Icons.auto_awesome_outlined, Icons.auto_awesome, '/assistant'),
  NavItem('Profile', Icons.person_outline, Icons.person, '/profile'),
];

/// Everything an admin can reach from the sidebar.
const adminNav = [
  NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard, '/admin'),
  NavItem('Bookings', Icons.event_note_outlined, Icons.event_note, '/admin/bookings'),
  NavItem('Services', Icons.spa_outlined, Icons.spa, '/admin/services'),
  NavItem('Discount requests', Icons.local_offer_outlined, Icons.local_offer, '/admin/discounts'),
  NavItem('Sales reports', Icons.bar_chart_outlined, Icons.bar_chart, '/admin/reports'),
  NavItem('Payment options', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, '/admin/payments'),
  NavItem('Custom fields', Icons.tune_outlined, Icons.tune, '/admin/fields'),
  NavItem('Profile', Icons.person_outline, Icons.person, '/admin/profile'),
];

/// Admin bottom bar: the four everyday screens plus "More", which opens the sidebar drawer
/// (reports, payment options, custom fields, profile, notifications, ...).
const adminBottomNav = [
  NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard, '/admin'),
  NavItem('Bookings', Icons.event_note_outlined, Icons.event_note, '/admin/bookings'),
  NavItem('Services', Icons.spa_outlined, Icons.spa, '/admin/services'),
  NavItem('Requests', Icons.local_offer_outlined, Icons.local_offer, '/admin/discounts'),
  NavItem('More', Icons.menu, Icons.menu_open, ''),
];

/// Index of the "More" entry in [adminBottomNav].
const adminMoreIndex = 4;

List<NavItem> navItemsFor(User user) => user.isAdmin ? adminNav : customerNav;
