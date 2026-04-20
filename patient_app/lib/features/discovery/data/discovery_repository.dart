import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/physio_model.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.watch(apiClientProvider));
});

class DiscoveryRepository {
  final ApiClient _api;
  DiscoveryRepository(this._api);

  Future<PhysioSearchResult> searchPhysios({
    double? lat, double? lng, double? radiusKm,
    String? specialty, String? bookingType, double? minRating, int page = 1,
  }) async {
    final res = await _api.get(ApiEndpoints.discoverPhysios, params: {
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
      if (radiusKm != null) 'radius_km': radiusKm,
      if (specialty != null) 'specialty': specialty,
      if (bookingType != null) 'booking_type': bookingType,
      if (minRating != null) 'min_rating': minRating,
      'page': page,
    });
    return PhysioSearchResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<PhysioDetail> getPhysioDetail(int physioId) async {
    final res = await _api.get(ApiEndpoints.physioDetail(physioId));
    return PhysioDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<String>> getAvailableSlots(int physioId, String date) async {
    final res = await _api.get(ApiEndpoints.physioAvailability(physioId), params: {'date': date});
    return List<String>.from(res.data['data'] as List);
  }
}
