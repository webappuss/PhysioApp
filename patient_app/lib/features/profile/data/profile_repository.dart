import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  final ApiClient _api;
  ProfileRepository(this._api);

  Future<PatientProfile> getProfile() async {
    final res = await _api.get(ApiEndpoints.patientProfile);
    return PatientProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PatientProfile> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put(ApiEndpoints.patientProfile, data: data);
    return PatientProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
