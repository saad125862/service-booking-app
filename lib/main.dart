import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

// Riverpod 3 retries failed providers by default; we show explicit "Try again" buttons instead.
Duration? _noRetry(int retryCount, Object error) => null;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(retry: _noRetry, child: const SebaApp()));
}
