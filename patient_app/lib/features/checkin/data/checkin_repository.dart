import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository(ref.watch(apiClientProvider));
});

class CheckinRepository {
  final ApiClient _api;
  CheckinRepository(this._api);

  Future<Map<String, dynamic>> submitCheckin({
    double? painScore,
    int? moodScore,
    double? sleepHours,
    int? energyLevel,
    String? notes,
  }) async {
    final res = await _api.post(ApiEndpoints.checkins, data: {
      if (painScore != null) 'pain_score': painScore,
      if (moodScore != null) 'mood_score': moodScore,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (notes != null && notes.isNotEmpty) 'patient_notes': notes,
    });
    return res.data['data'] as Map<String, dynamic>? ?? {};
  }
}
