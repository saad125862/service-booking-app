/// Form validators. They mirror the backend rules so users get instant feedback,
/// while the server remains the source of truth.
class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 100) return 'Name is too long';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Registration / change-password rule: 8-72 chars, at least one letter and one number.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (v.length > 72) return 'Use at most 72 characters';
    if (!RegExp('[A-Za-z]').hasMatch(v)) return 'Include at least one letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include at least one number';
    return null;
  }

  /// Login only checks presence; the server decides if it is correct.
  static String? password(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password' : null;

  static String? Function(String?) confirmPassword(String Function() original) =>
      (value) {
        if (value == null || value.isEmpty) return 'Confirm your password';
        if (value != original()) return 'Passwords do not match';
        return null;
      };

  /// Optional phone: digits, spaces, +, (), - (6-30 chars).
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9 ()-]{6,30}$').hasMatch(v)) return 'Enter a valid phone number';
    return null;
  }
}
