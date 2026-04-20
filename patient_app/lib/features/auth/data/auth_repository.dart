import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(authStorageProvider));
});

class AuthRepository {
  final ApiClient _api;
  final AuthStorage _storage;
  AuthRepository(this._api, this._storage);

  Future<void> sendOtp(String phone) async {
    await _api.post(ApiEndpoints.sendOtp, data: {'phone': phone, 'purpose': 'login'});
  }

  Future<AuthUser> verifyOtp(String phone, String otp) async {
    final res = await _api.post(ApiEndpoints.verifyOtp, data: {
      'phone': phone,
      'otp': otp,
      'role': 'patient',
    });

    final data = res.data['data'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.saveSession(
      token: data['token'] as String,
      userId: user.id,
      role: user.role,
      phone: user.phone,
    );

    return user;
  }

  Future<AuthUser> getMe() async {
    final res = await _api.get(ApiEndpoints.me);
    return AuthUser.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try { await _api.post(ApiEndpoints.logout); } catch (_) {}
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() => _storage.isLoggedIn();
}
