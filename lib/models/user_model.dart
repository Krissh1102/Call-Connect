import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String passwordHash; // mock backend only — never store plaintext
  final bool isOnline;
  final DateTime? lastSeen;
  final String avatarColorHex; // deterministic color for the initials avatar

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.passwordHash,
    this.isOnline = false,
    this.lastSeen,
    this.avatarColorHex = '#4F63F6',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    bool? isOnline,
    DateTime? lastSeen,
    String? avatarColorHex,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'passwordHash': passwordHash,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
        'avatarColorHex': avatarColorHex,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        passwordHash: json['passwordHash'] as String,
        isOnline: json['isOnline'] as bool? ?? false,
        lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'] as String) : null,
        avatarColorHex: json['avatarColorHex'] as String? ?? '#4F63F6',
      );

  /// Public-facing view (no password hash) used anywhere a peer's profile is shown.
  UserModel get publicView => copyWith();

  @override
  List<Object?> get props => [id, name, email, phone, isOnline, lastSeen, avatarColorHex];
}
