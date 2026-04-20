import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage(ref.watch(secureStorageProvider));
});

class AuthStorage {
  final FlutterSecureStorage _storage;
  AuthStorage(this._storage);

  Future<void> saveSession({
    required String token,
    required int userId,
    required String role,
    required String phone,
  }) async {
    await Future.wait([
      _storage.write(key: 'auth_token',  value: token),
      _storage.write(key: 'user_id',     value: userId.toString()),
      _storage.write(key: 'user_role',   value: role),
      _storage.write(key: 'user_phone',  value: phone),
    ]);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() => _storage.read(key: 'auth_token');
  Future<String?> getPhone() => _storage.read(key: 'user_phone');

  Future<void> clearSession() => _storage.deleteAll();
}
