import 'doctor.dart';

enum UserRole {
  owner,
  doctor;

  bool get isOwner => this == UserRole.owner;
  bool get isDoctor => this == UserRole.doctor;
}

class UserSession {
  final UserRole role;
  final Doctor? doctor; // Set when role == UserRole.doctor

  const UserSession({
    required this.role,
    this.doctor,
  });

  static const UserSession unauthenticated = UserSession(role: UserRole.owner, doctor: null);
}
