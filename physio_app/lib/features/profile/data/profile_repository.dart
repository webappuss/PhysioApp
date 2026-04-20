import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/physio_profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  final ApiClient _api;
  ProfileRepository(this._api);

  Future<PhysioProfile> getProfile() async {
    final res = await _api.get(ApiEndpoints.physioProfile);
    return PhysioProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PhysioProfile> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put(ApiEndpoints.physioProfile, data: data);
    return PhysioProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
