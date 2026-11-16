import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// Asks "Sign out?" and returns true only when the user confirms. Call it with a context that is still
/// mounted when the dialog opens (e.g. before a drawer is closed).
Future<bool> askSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.logout),
      title: const Text('Sign out?'),
      content: const Text('You will need to sign in again to book or manage services.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay signed in')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks for confirmation, then signs the user out. The router sends them to the login screen.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final auth = ref.read(authProvider.notifier);
  if (await askSignOut(context)) await auth.logout();
}
