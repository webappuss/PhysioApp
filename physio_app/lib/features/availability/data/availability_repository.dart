import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/availability_model.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return AvailabilityRepository(ref.watch(apiClientProvider));
});

class AvailabilityRepository {
  final ApiClient _api;
  AvailabilityRepository(this._api);

  Future<List<AvailabilitySlot>> getAvailability() async {
    final res = await _api.get(ApiEndpoints.physioAvailability);
    return (res.data['data'] as List? ?? [])
        .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAvailability(List<AvailabilitySlot> slots) async {
    await _api.put(ApiEndpoints.physioAvailability,
        data: {'availability': slots.map((s) => s.toJson()).toList()});
  }
}
