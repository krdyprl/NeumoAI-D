class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.phone,
    required this.emoji,
    required this.role,
  });

  final String name;
  final String email;
  final String phone;
  final String emoji;
  final String role;

  Profile copyWith({String? name, String? email, String? phone, String? emoji, String? role}) =>
      Profile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        emoji: emoji ?? this.emoji,
        role: role ?? this.role,
      );
}
