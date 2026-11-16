import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/services/presentation/home_screen.dart';
import '../../features/booking/domain/appointment.dart';
import '../../features/booking/presentation/booking_confirmation_screen.dart';
import '../../features/booking/presentation/booking_details_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/services/domain/service.dart';
import '../../features/services/presentation/service_details_screen.dart';
import '../../features/shell/home_shell.dart';

const _authRoutes = {'/login', '/register'};

/// Where the user should be, given the auth state and the current location.
/// Returns null when the current location is fine.
///
/// - restoring the session (or failed to) -> /splash, remembering where the user was headed
/// - after restoring, /splash sends them to that place (e.g. after a page refresh)
/// - signed out -> /login (or /register)
/// - customers -> the tabs; admins -> /admin, and neither can open the other's area
String? appRedirect(AsyncValue<User?> auth, String location, {String? from}) {
  if (auth.isLoading || auth.hasError) {
    if (location == '/splash') return null;
    return '/splash?from=${Uri.encodeQueryComponent(location)}';
  }

  final user = auth.value;
  if (user == null) return _authRoutes.contains(location) ? null : '/login';

  final home = user.isAdmin ? '/admin' : '/';
  if (location == '/splash') return _safeTarget(from, user) ?? home;
  if (_authRoutes.contains(location)) return home;
  if (user.isAdmin && !location.startsWith('/admin')) return '/admin';
  if (!user.isAdmin && location.startsWith('/admin')) return '/';
  return null;
}

/// The remembered location, if it is a normal in-app path this user may open.
String? _safeTarget(String? from, User user) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
  if (from == '/splash' || _authRoutes.contains(from)) return null;
  if (user.isAdmin != from.startsWith('/admin')) return null;
  return from;
}

/// App routes. Redirects are driven by the auth state (see [appRedirect]).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      ref.read(authProvider),
      state.matchedLocation,
      from: state.uri.queryParameters['from'],
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminHomeScreen()),
      GoRoute(
        path: '/service/:id',
        builder: (_, state) => ServiceDetailsScreen(
          serviceId: state.pathParameters['id']!,
          initial: state.extra as Service?,
        ),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, state) => BookingScreen(
              serviceId: state.pathParameters['id']!,
              service: state.extra as Service?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, state) => BookingDetailsScreen(
          appointmentId: state.pathParameters['id']!,
          initial: state.extra as Appointment?,
        ),
        routes: [
          GoRoute(
            path: 'confirmed',
            builder: (_, state) => BookingConfirmationScreen(
              appointmentId: state.pathParameters['id']!,
              initial: state.extra as Appointment?,
            ),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/bookings', builder: (_, _) => const BookingsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/assistant', builder: (_, _) => const AssistantScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
