import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final authAsync = ref.watch(authStateProvider);
    final name = authAsync.valueOrNull?.user?.name ?? 'Doctor';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.cardWhite,
              automaticallyImplyLeading: false,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good ${_greeting()}, Dr. $name',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Text("Here's your day at a glance",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
            dashAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text(e.toString()))),
              data: (dash) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  _StatsGrid(dash: dash),
                  const SizedBox(height: 20),
                  _EarningsCard(dash: dash),
                  const SizedBox(height: 20),
                  const Text('Today\'s Appointments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  if (dash.upcomingBookings.isEmpty)
                    _EmptyAppointments()
                  else
                    ...dash.upcomingBookings.map((b) => _BookingCard(booking: b)),
                ])),
              ),
            ),
          ],
        ),
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

class _StatsGrid extends StatelessWidget {
  final PhysioDashboard dash;
  const _StatsGrid({required this.dash});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _StatCard('Today', '${dash.todayBookings}', 'Sessions', Icons.today, AppTheme.primaryGreen),
        _StatCard('Pending', '${dash.pendingBookings}', 'Requests', Icons.pending_outlined, AppTheme.warningAmber),
        _StatCard('Patients', '${dash.totalPatients}', 'Total', Icons.people_outline, AppTheme.accentBlue),
        _StatCard('Rating', dash.rating.toStringAsFixed(1), '${dash.totalReviews} reviews', Icons.star_outline, Colors.orange),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.subtitle, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ])),
    ]),
  );
}

class _EarningsCard extends StatelessWidget {
  final PhysioDashboard dash;
  const _EarningsCard({required this.dash});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primaryGreen, Color(0xFF00695C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('This Month', style: TextStyle(fontSize: 13, color: Colors.white70)),
          Text('₹${dash.monthEarnings.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('Total Earned', style: TextStyle(fontSize: 13, color: Colors.white70)),
          Text('₹${dash.totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ],
    ),
  );
}

class _BookingCard extends StatelessWidget {
  final UpcomingBooking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/bookings/${booking.id}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            booking.bookingType == 'video_consult' ? Icons.video_call : Icons.home_outlined,
            color: AppTheme.primaryGreen, size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.patientName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text('${booking.scheduledDate} · ${booking.scheduledTime.substring(0, 5)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${booking.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
          _StatusChip(booking.status),
        ]),
      ]),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' || 'completed' => AppTheme.successGreen,
      'pending'   => AppTheme.warningAmber,
      'cancelled' => AppTheme.errorRed,
      _           => AppTheme.textSecondary,
    };
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: const Column(children: [
      Icon(Icons.event_available_outlined, size: 48, color: AppTheme.textSecondary),
      SizedBox(height: 8),
      Text('No appointments today', style: TextStyle(color: AppTheme.textSecondary)),
    ]),
  );
}
