class User {
  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.token,
    this.isActive = true,
    this.stats,
  });

  final String id;
  final String username;
  final String name;
  final String role;
  final String? token;
  final bool isActive;
  final Map<String, dynamic>? stats;

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      token: json['token']?.toString(),
      isActive: json['isActive'] != false,
      stats: json['stats'] is Map<String, dynamic>
          ? json['stats'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'name': name,
      'role': role,
      'token': token,
      'isActive': isActive,
      if (stats != null) 'stats': stats,
    };
  }
}
