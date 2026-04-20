class AuthUser {
  final int id;
  final String uuid;
  final String phone;
  final String? email;
  final String name;
  final String role;
  final String status;

  const AuthUser({
    required this.id,
    required this.uuid,
    required this.phone,
    this.email,
    required this.name,
    required this.role,
    required this.status,
  });

  bool get isLoggedIn => true;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id:     json['id'] as int,
    uuid:   json['uuid'] as String,
    phone:  json['phone'] as String,
    email:  json['email'] as String?,
    name:   json['name'] as String,
    role:   json['role'] as String,
    status: json['status'] as String,
  );
}

class AuthState {
  final bool isLoggedIn;
  final AuthUser? user;
  AuthState({required this.isLoggedIn, this.user});
  AuthState.loggedOut() : isLoggedIn = false, user = null;
}
