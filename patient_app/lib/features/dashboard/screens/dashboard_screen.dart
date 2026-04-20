import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final authAsync = ref.watch(authStateProvider);
    final userName  = authAsync.valueOrNull?.user?.name.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(userName: userName)),
              dashAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text(e.toString())),
                ),
                data: (data) => SliverList(
                  delegate: SliverChildListDelegate([
                    _XpStreak(data: data),
                    if (!data.checkinDoneToday) _CheckinBanner(),
                    if (data.upcomingBookings.isNotEmpty) _UpcomingBookings(bookings: data.upcomingBookings),
                    if (data.exercisesToday.isNotEmpty) _TodayExercises(exercises: data.exercisesToday),
                    if (data.activeRehabPlan != null) _RehabPlanCard(plan: data.activeRehabPlan!),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String userName;
  const _Header({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good ${_greeting()}, $userName 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ]),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _XpStreak extends StatelessWidget {
  final DashboardData data;
  const _XpStreak({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF0D4FA8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Stat(value: '${data.streakDays}', label: 'Day Streak', icon: '🔥'),
          const SizedBox(width: 24),
          _Stat(value: '${data.totalXp}', label: 'Total XP', icon: '⭐'),
          const SizedBox(width: 24),
          _Stat(value: 'Lv ${data.level}', label: 'Level', icon: '🏆'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label, icon;
  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$icon $value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
    ],
  );
}

class _CheckinBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/checkin'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accentTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentTeal.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Check-in", style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text('Log your pain, mood & energy', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.accentTeal),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBookings extends StatelessWidget {
  final List<Booking> bookings;
  const _UpcomingBookings({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('Upcoming Sessions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ),
        ...bookings.map((b) => _BookingCard(booking: b)),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bookings/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.bookingType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                Text('${booking.scheduledDate} at ${booking.scheduledTime.substring(0, 5)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text('₹${booking.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ]),
            ),
            _StatusChip(status: booking.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'confirmed' ? AppTheme.successGreen
        : status == 'pending' ? AppTheme.warningAmber : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TodayExercises extends StatelessWidget {
  final List<Exercise> exercises;
  const _TodayExercises({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Exercises", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('${exercises.length} exercises', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: exercises.length,
            itemBuilder: (_, i) => _ExerciseChip(exercise: exercises[i]),
          ),
        ),
      ],
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseChip({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(exercise.name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          if (exercise.category != null)
            Text(exercise.category!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _RehabPlanCard extends StatelessWidget {
  final RehabPlan plan;
  const _RehabPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final progress = plan.currentPhase / plan.totalPhases;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Rehab Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            Text('Phase ${plan.currentPhase}/${plan.totalPhases}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
          ],
        ),
        const SizedBox(height: 6),
        Text(plan.title ?? plan.condition ?? 'Active Rehabilitation',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
          ),
        ),
      ]),
    );
  }
}
