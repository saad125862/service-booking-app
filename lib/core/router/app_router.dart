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
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/services/domain/service.dart';
import '../../features/services/presentation/service_details_screen.dart';
import '../../features/shell/home_shell.dart';

const _authRoutes = {'/login', '/register'};

/// Where the user should be, given the auth state and the current location.
/// Returns null when the current location is fine.
///
/// - restoring the session (or failed to) -> /splash
/// - signed out -> /login (or /register)
/// - customers -> the tabs; admins -> /admin, and neither can open the other's area
String? appRedirect(AsyncValue<User?> auth, String location) {
  if (auth.isLoading || auth.hasError) return location == '/splash' ? null : '/splash';

  final user = auth.value;
  if (user == null) return _authRoutes.contains(location) ? null : '/login';

  final home = user.isAdmin ? '/admin' : '/';
  if (location == '/splash' || _authRoutes.contains(location)) return home;
  if (user.isAdmin && !location.startsWith('/admin')) return '/admin';
  if (!user.isAdmin && location.startsWith('/admin')) return '/';
  return null;
}

/// App routes. Redirects are driven by the auth state (see [appRedirect]).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(ref.read(authProvider), state.matchedLocation),
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
