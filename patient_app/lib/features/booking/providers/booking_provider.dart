import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';
import '../models/booking_model.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<BookingDetail>>((ref) {
  return ref.watch(bookingRepositoryProvider).getMyBookings();
});

final bookingDetailProvider = FutureProvider.autoDispose.family<BookingDetail, int>((ref, id) {
  return ref.watch(bookingRepositoryProvider).getBooking(id);
});

class CreateBookingNotifier extends AsyncNotifier<BookingDetail?> {
  @override
  Future<BookingDetail?> build() async => null;

  Future<BookingDetail?> create({
    required int physioId,
    required String bookingType,
    required String date,
    required String time,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
      ref.read(bookingRepositoryProvider).createBooking(
        physioId: physioId, bookingType: bookingType,
        scheduledDate: date, scheduledTime: time,
      ),
    );
    state = result;
    if (result.hasValue) ref.invalidate(myBookingsProvider);
    return result.valueOrNull;
  }
}

final createBookingProvider = AsyncNotifierProvider<CreateBookingNotifier, BookingDetail?>(
  CreateBookingNotifier.new,
);

class CancelBookingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> cancel(int bookingId, {String? reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(bookingRepositoryProvider).cancelBooking(bookingId, reason: reason),
    );
    if (!state.hasError) {
      ref.invalidate(myBookingsProvider);
      ref.invalidate(bookingDetailProvider(bookingId));
    }
  }
}

final cancelBookingProvider = AsyncNotifierProvider<CancelBookingNotifier, void>(CancelBookingNotifier.new);
