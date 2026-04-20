import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/phone_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/discovery/screens/discovery_screen.dart';
import '../../features/discovery/screens/physio_detail_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/booking/screens/booking_detail_screen.dart';
import '../../features/booking/screens/my_bookings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/exercise/screens/rehab_plans_screen.dart';
import '../../features/exercise/screens/rehab_plan_detail_screen.dart';
import '../../features/exercise/screens/exercise_detail_screen.dart';
import '../../features/exercise/models/exercise_model.dart';
import '../../features/scores/screens/scores_screen.dart';
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
      // Auth flow
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpScreen(phone: state.extra as String),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/discover',  builder: (_, __) => const DiscoveryScreen()),
          GoRoute(path: '/bookings',  builder: (_, __) => const MyBookingsScreen()),
          GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Detail screens (outside shell)
      GoRoute(
        path: '/physio/:id',
        builder: (_, state) => PhysioDetailScreen(physioId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/book/:physioId',
        builder: (_, state) => BookingScreen(physioId: int.parse(state.pathParameters['physioId']!)),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, state) => BookingDetailScreen(bookingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/checkin',
        builder: (_, __) => const CheckinScreen(),
      ),
      GoRoute(
        path: '/payment/:bookingId',
        builder: (_, state) => PaymentScreen(bookingId: int.parse(state.pathParameters['bookingId']!)),
      ),
      GoRoute(
        path: '/rehab-plans',
        builder: (_, __) => const RehabPlansScreen(),
      ),
      GoRoute(
        path: '/rehab-plans/:id',
        builder: (_, state) => RehabPlanDetailScreen(planId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/exercises/:id',
        builder: (_, state) => ExerciseDetailScreen(exercise: state.extra as Exercise),
      ),
      GoRoute(
        path: '/scores',
        builder: (_, __) => const ScoresScreen(),
      ),
    ],
  );
});
