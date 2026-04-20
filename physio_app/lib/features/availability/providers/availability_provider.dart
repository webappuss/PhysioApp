import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/availability_repository.dart';
import '../models/availability_model.dart';

final availabilityProvider = FutureProvider.autoDispose<List<AvailabilitySlot>>((ref) {
  return ref.watch(availabilityRepositoryProvider).getAvailability();
});

class AvailabilityNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(List<AvailabilitySlot> slots) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(availabilityRepositoryProvider).updateAvailability(slots),
    );
    if (!state.hasError) ref.invalidate(availabilityProvider);
  }
}

final availabilityNotifierProvider = AsyncNotifierProvider<AvailabilityNotifier, void>(
  AvailabilityNotifier.new,
);
