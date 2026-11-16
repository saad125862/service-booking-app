class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.phone,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  /// `user` (customer) or `admin`.
  final String role;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'user',
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
      );

  /// First letter(s) for avatars.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
