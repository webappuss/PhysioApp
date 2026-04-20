import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/phone_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/bookings/screens/bookings_screen.dart';
import '../../features/bookings/screens/booking_detail_screen.dart';
import '../../features/patients/screens/patients_screen.dart';
import '../../features/sessions/screens/soap_notes_screen.dart';
import '../../features/availability/screens/availability_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isLoggedIn ?? false;
      final onAuthPage  = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !onAuthPage) return '/auth/phone';
      if (isLoggedIn && onAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpScreen(phone: state.extra as String),
      ),

      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/bookings',  builder: (_, __) => const BookingsScreen()),
          GoRoute(path: '/patients',  builder: (_, __) => const PatientsScreen()),
          GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(
        path: '/bookings/:id',
        builder: (_, state) => BookingDetailScreen(bookingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/sessions/soap/:bookingId',
        builder: (_, state) => SoapNotesScreen(bookingId: int.parse(state.pathParameters['bookingId']!)),
      ),
      GoRoute(path: '/availability', builder: (_, __) => const AvailabilityScreen()),
    ],
  );
});
