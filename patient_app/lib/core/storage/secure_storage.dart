import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

class AuthStorage {
  static const _tokenKey    = 'auth_token';
  static const _userIdKey   = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _userPhoneKey= 'user_phone';

  final FlutterSecureStorage _storage;
  AuthStorage(this._storage);

  Future<void> saveSession({
    required String token,
    required int userId,
    required String role,
    required String phone,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId.toString()),
      _storage.write(key: _userRoleKey, value: role),
      _storage.write(key: _userPhoneKey, value: phone),
    ]);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getRole()  => _storage.read(key: _userRoleKey);
  Future<String?> getPhone() => _storage.read(key: _userPhoneKey);

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() => _storage.deleteAll();
}

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(ref.watch(secureStorageProvider));
});
