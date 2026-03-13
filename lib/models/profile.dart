class Profile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? studentId;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.studentId,
    this.avatarUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      role: map['role'] as String,
      studentId: map['student_id'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
}
