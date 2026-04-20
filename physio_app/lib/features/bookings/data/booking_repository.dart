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

  Future<List<BookingDetail>> getBookings({String? status}) async {
    final res = await _api.get(ApiEndpoints.bookings,
        params: status != null ? {'status': status} : null);
    return (res.data['data'] as List? ?? [])
        .map((e) => BookingDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingDetail> getBookingDetail(int id) async {
    final res = await _api.get(ApiEndpoints.bookingDetail(id));
    return BookingDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> confirmBooking(int id) =>
      _api.put(ApiEndpoints.confirmBooking(id));

  Future<void> startBooking(int id) =>
      _api.put(ApiEndpoints.startBooking(id));

  Future<void> completeBooking(int id) =>
      _api.put(ApiEndpoints.completeBooking(id));

  Future<void> cancelBooking(int id, String reason) =>
      _api.put(ApiEndpoints.cancelBooking(id), data: {'reason': reason});
}
