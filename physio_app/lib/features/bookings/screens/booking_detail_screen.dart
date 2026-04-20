import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';
import '../../../core/theme/app_theme.dart';

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Detail')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (booking) => _BookingBody(booking: booking, ref: ref),
      ),
    );
  }
}

class _BookingBody extends StatelessWidget {
  final BookingDetail booking;
  final WidgetRef ref;
  const _BookingBody({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _StatusCard(booking: booking),
        const SizedBox(height: 16),
        _PatientCard(booking: booking),
        const SizedBox(height: 16),
        _SessionInfoCard(booking: booking),
        const SizedBox(height: 24),
        _ActionButtons(booking: booking, ref: ref),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final BookingDetail booking;
  const _StatusCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(_statusIcon(booking.status), color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          Text('Booking #${booking.id}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        const Spacer(),
        Text('₹${booking.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      ]),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'confirmed' || 'completed' => AppTheme.successGreen,
    'pending'   => AppTheme.warningAmber,
    'cancelled' => AppTheme.errorRed,
    _           => AppTheme.textSecondary,
  };

  IconData _statusIcon(String s) => switch (s) {
    'confirmed'  => Icons.check_circle_outline,
    'completed'  => Icons.done_all,
    'pending'    => Icons.access_time,
    'cancelled'  => Icons.cancel_outlined,
    _            => Icons.info_outline,
  };
}

class _PatientCard extends StatelessWidget {
  final BookingDetail booking;
  const _PatientCard({required this.booking});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        child: Text(
          (booking.patientName?.isNotEmpty == true ? booking.patientName![0] : 'P').toUpperCase(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(booking.patientName ?? 'Patient',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        if (booking.patientPhone != null)
          Text('+91 ${booking.patientPhone}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        if (booking.address != null)
          Text(booking.address!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ])),
      if (booking.patientPhone != null)
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: AppTheme.primaryGreen),
          onPressed: () {},
        ),
    ]),
  );
}

class _SessionInfoCard extends StatelessWidget {
  final BookingDetail booking;
  const _SessionInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Session Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      _Row('Type', booking.bookingType.replaceAll('_', ' ')),
      _Row('Date', booking.scheduledDate),
      _Row('Time', booking.scheduledTime.substring(0, 5)),
      _Row('Payment', booking.paymentStatus),
      if (booking.notes != null && booking.notes!.isNotEmpty)
        _Row('Notes', booking.notes!),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
      ],
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  final BookingDetail booking;
  final WidgetRef ref;
  const _ActionButtons({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    final actionAsync = ref.watch(bookingActionProvider);
    final loading = actionAsync.isLoading;

    Future<void> act(Future<void> Function() action) async {
      await action();
      final state = ref.read(bookingActionProvider);
      if (state.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    }

    return Column(children: [
      if (booking.status == 'pending') ...[
        ElevatedButton(
          onPressed: loading ? null : () => act(() => ref.read(bookingActionProvider.notifier).confirm(booking.id)),
          child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm Booking'),
        ),
        const SizedBox(height: 10),
      ],
      if (booking.status == 'confirmed') ...[
        ElevatedButton(
          onPressed: loading ? null : () => act(() => ref.read(bookingActionProvider.notifier).start(booking.id)),
          child: const Text('Start Session'),
        ),
        const SizedBox(height: 10),
      ],
      if (booking.status == 'in_progress') ...[
        ElevatedButton(
          onPressed: loading ? null : () async {
            await act(() => ref.read(bookingActionProvider.notifier).complete(booking.id));
            if (context.mounted) context.push('/sessions/soap/${booking.id}');
          },
          child: const Text('Complete & Add SOAP Notes'),
        ),
        const SizedBox(height: 10),
      ],
      if (booking.status == 'completed' && booking.sessionId != null) ...[
        OutlinedButton(
          onPressed: () => context.push('/sessions/soap/${booking.id}'),
          child: const Text('View/Edit SOAP Notes'),
        ),
        const SizedBox(height: 10),
      ],
      if (booking.status != 'cancelled' && booking.status != 'completed') ...[
        OutlinedButton(
          onPressed: loading ? null : () => _showCancelDialog(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorRed,
            side: const BorderSide(color: AppTheme.errorRed),
          ),
          child: const Text('Cancel Booking'),
        ),
      ],
    ]);
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Reason for cancellation'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(bookingActionProvider.notifier).cancel(booking.id, ctrl.text);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }
}
