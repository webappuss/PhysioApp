import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';
import '../models/booking_model.dart';

final bookingsProvider = FutureProvider.autoDispose<List<BookingDetail>>((ref) {
  return ref.watch(bookingRepositoryProvider).getBookings();
});

final bookingDetailProvider = FutureProvider.autoDispose.family<BookingDetail, int>((ref, id) {
  return ref.watch(bookingRepositoryProvider).getBookingDetail(id);
});

class BookingActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> confirm(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).confirmBooking(id),
    );
    if (!state.hasError) {
      ref.invalidate(bookingDetailProvider(id));
      ref.invalidate(bookingsProvider);
    }
  }

  Future<void> start(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).startBooking(id),
    );
    if (!state.hasError) {
      ref.invalidate(bookingDetailProvider(id));
      ref.invalidate(bookingsProvider);
    }
  }

  Future<void> complete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).completeBooking(id),
    );
    if (!state.hasError) {
      ref.invalidate(bookingDetailProvider(id));
      ref.invalidate(bookingsProvider);
    }
  }

  Future<void> cancel(int id, String reason) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).cancelBooking(id, reason),
    );
    if (!state.hasError) {
      ref.invalidate(bookingDetailProvider(id));
      ref.invalidate(bookingsProvider);
    }
  }
}

final bookingActionProvider = AsyncNotifierProvider<BookingActionNotifier, void>(
  BookingActionNotifier.new,
);
