import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/theme_mode_selector.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/sign_out_dialog.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../shell/shell_scope.dart';

/// View and edit personal details, change the password, pick light or dark mode, sign out.
/// Shared by customers and admins.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: shellMenuLeading(context),
        actions: const [NotificationBell()],
      ),
      // The form is created only once the user is known, so its fields start with the saved values.
      body: user == null ? const SizedBox.shrink() : _ProfileBody(user: user),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.user});

  final User user;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  final _infoKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  final _passwordKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  bool _changing = false;
  String? _infoError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name.text = user.name;
    _phone.text = user.phone ?? '';
    _address.text = user.address ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _current, _new, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveInfo() async {
    FocusScope.of(context).unfocus();
    if (!_infoKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _infoError = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _name.text,
            phone: _phone.text,
            address: _address.text,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _infoError = e.details.isNotEmpty ? e.details.values.join('\n') : e.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!_passwordKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _changing = true;
      _passwordError = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      for (final c in [_current, _new, _confirm]) {
        c.clear();
      }
      messenger.showSnackBar(const SnackBar(content: Text('Password changed')));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _passwordError = e.details.isNotEmpty ? e.details.values.join('\n') : e.message);
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value ?? widget.user;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    user.initials,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (user.isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: const Text('Admin account'),
                      backgroundColor: scheme.primaryContainer,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Personal details',
              child: Form(
                key: _infoKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_infoError != null) ...[
                      StatusBanner(message: _infoError!),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                      controller: _name,
                      label: 'Full name',
                      prefixIcon: Icons.person_outline,
                      validator: Validators.name,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone (optional)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      enabled: !_saving,
                    ),
                    if (!user.isAdmin) ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _address,
                        label: 'Default service address (optional)',
                        hint: 'Used to prefill your bookings',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        maxLength: 300,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? null
                            : Validators.address(v),
                        enabled: !_saving,
                      ),
                    ],
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Save changes',
                      onPressed: _saveInfo,
                      loading: _saving,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Change password',
              child: Form(
                key: _passwordKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_passwordError != null) ...[
                      StatusBanner(message: _passwordError!),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                      controller: _current,
                      label: 'Current password',
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      validator: Validators.password,
                      enabled: !_changing,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _new,
                      label: 'New password',
                      hint: 'At least 8 characters, a letter and a number',
                      prefixIcon: Icons.lock_reset,
                      obscure: true,
                      validator: Validators.newPassword,
                      enabled: !_changing,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirm new password',
                      prefixIcon: Icons.lock_reset,
                      obscure: true,
                      validator: Validators.confirmPassword(() => _new.text),
                      enabled: !_changing,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Change password',
                      outlined: true,
                      onPressed: _changePassword,
                      loading: _changing,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Appearance',
              child: const Align(
                alignment: Alignment.centerLeft,
                child: ThemeModeSelector(),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
              onPressed: () => confirmSignOut(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
