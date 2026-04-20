import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(apiClientProvider));
});

class BookingRepository {
  final ApiClient _api;
  BookingRepository(this._api);

  Future<BookingDetail> createBooking({
    required int physioId,
    required String bookingType,
    required String scheduledDate,
    required String scheduledTime,
    int? addressId,
  }) async {
    final res = await _api.post(ApiEndpoints.bookings, data: {
      'physio_id': physioId,
      'booking_type': bookingType,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      if (addressId != null) 'address_id': addressId,
    });
    return BookingDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<BookingDetail> getBooking(int id) async {
    final res = await _api.get(ApiEndpoints.bookingDetail(id));
    return BookingDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<BookingDetail>> getMyBookings() async {
    final res = await _api.get(ApiEndpoints.bookings);
    return (res.data['data'] as List? ?? [])
        .map((e) => BookingDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingDetail> cancelBooking(int id, {String? reason}) async {
    final res = await _api.put(ApiEndpoints.cancelBooking(id), data: {
      if (reason != null) 'reason': reason,
    });
    return BookingDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getTracking(int id) async {
    final res = await _api.get(ApiEndpoints.bookingTracking(id));
    return res.data['data'] as Map<String, dynamic>? ?? {};
  }
}
