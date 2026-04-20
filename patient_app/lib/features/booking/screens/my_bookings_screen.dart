import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../../core/theme/app_theme.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myBookingsProvider.future),
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (bookings) => bookings.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) => _BookingTile(booking: bookings[i]),
                ),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final BookingDetail booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _color(booking.status);
    return GestureDetector(
      onTap: () => context.push('/bookings/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(booking.bookingType.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(booking.status.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(booking.physioName ?? 'Physiotherapist',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today, size: 13, color: AppTheme.textSecondary),
            Text('  ${booking.scheduledDate} at ${booking.scheduledTime.substring(0, 5)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const Spacer(),
            Text('₹${booking.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
          ]),
        ]),
      ),
    );
  }

  Color _color(String s) => switch (s) {
    'confirmed' || 'completed' => AppTheme.successGreen,
    'pending'   => AppTheme.warningAmber,
    'cancelled' => AppTheme.errorRed,
    _           => AppTheme.textSecondary,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textSecondary),
      const SizedBox(height: 12),
      const Text('No bookings yet', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: () => context.go('/discover'),
        child: const Text('Find a Physiotherapist'),
      ),
    ]),
  );
}
