import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../models/profile_model.dart';

final profileProvider = FutureProvider.autoDispose<PatientProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

class ProfileUpdateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> update(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(data);
      ref.invalidate(profileProvider);
    });
  }
}

final profileUpdateProvider = AsyncNotifierProvider<ProfileUpdateNotifier, void>(
  ProfileUpdateNotifier.new,
);
