class AuthUser {
  final int id;
  final String uuid;
  final String phone;
  final String? email;
  final String? name;
  final String role;
  final String status;

  const AuthUser({
    required this.id,
    required this.uuid,
    required this.phone,
    this.email,
    this.name,
    required this.role,
    required this.status,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id:     j['id'] as int,
    uuid:   j['uuid'] as String,
    phone:  j['phone'] as String,
    email:  j['email'] as String?,
    name:   j['name'] as String?,
    role:   j['role'] as String,
    status: j['status'] as String,
  );
}

class AuthState {
  final bool isLoggedIn;
  final AuthUser? user;

  const AuthState({required this.isLoggedIn, this.user});

  factory AuthState.loggedOut() => const AuthState(isLoggedIn: false);
}
