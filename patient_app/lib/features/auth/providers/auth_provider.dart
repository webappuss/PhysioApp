import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';

final authStateProvider = FutureProvider<AuthState>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final isLoggedIn = await repo.isLoggedIn();
  if (!isLoggedIn) return AuthState.loggedOut();
  try {
    final user = await repo.getMe();
    return AuthState(isLoggedIn: true, user: user);
  } catch (_) {
    return AuthState.loggedOut();
  }
});

// OTP Send
class OtpSendNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendOtp(phone),
    );
  }
}

final otpSendProvider = AsyncNotifierProvider<OtpSendNotifier, void>(OtpSendNotifier.new);

// OTP Verify
class OtpVerifyNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async => null;

  Future<AuthUser?> verify(String phone, String otp) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(phone, otp),
    );
    state = result;
    if (result.hasValue) {
      ref.invalidate(authStateProvider);
    }
    return result.valueOrNull;
  }
}

final otpVerifyProvider = AsyncNotifierProvider<OtpVerifyNotifier, AuthUser?>(OtpVerifyNotifier.new);

// Logout
class LogoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(authStateProvider);
    state = const AsyncData(null);
  }
}

final logoutProvider = AsyncNotifierProvider<LogoutNotifier, void>(LogoutNotifier.new);
