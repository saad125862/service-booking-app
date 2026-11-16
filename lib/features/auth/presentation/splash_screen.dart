import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/seba_logo.dart';
import '../../../core/widgets/state_views.dart';
import 'auth_controller.dart';

/// Shown while the saved session is restored. If the server can't be reached it
/// offers a retry instead of logging the user out.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.hasError && !auth.isLoading) {
      final error = auth.error;
      return Scaffold(
        body: SafeArea(
          child: ErrorView(
            title: "Can't connect",
            message: error is ApiException ? error.message : 'Something went wrong. Please try again.',
            onRetry: () => ref.invalidate(authProvider),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SebaLogo(size: 88),
              const SizedBox(height: 20),
              Text(
                'Seba',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),
              const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            ],
          ),
        ),
      ),
    );
  }
}
