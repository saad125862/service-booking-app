import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_banner.dart';
import 'auth_controller.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(email: _email.text, password: _password.text);
      // The router redirects to the right home screen once the auth state changes.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// One-tap sign in for the seeded demo accounts.
  Future<void> _quickSignIn(String email, String password) {
    _email.text = email;
    _password.text = password;
    return _submit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to book and manage your services.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[StatusBanner(message: _error!), const SizedBox(height: 16)],
              AppTextField(
                controller: _email,
                label: 'Email',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !_submitting,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _password,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
                enabled: !_submitting,
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Sign in', onPressed: _submit, loading: _submitting),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Quick sign in (demo)',
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _quickSignIn(AppConfig.demoCustomerEmail, AppConfig.demoCustomerPassword),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => _quickSignIn(AppConfig.demoAdminEmail, AppConfig.demoAdminPassword),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            context.go('/register');
                          },
                    child: const Text('Create one'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
