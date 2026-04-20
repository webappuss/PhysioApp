import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
      appBar: AppBar(title: const Text('Booking Details')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (booking) => _Body(booking: booking, ref: ref),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final BookingDetail booking;
  final WidgetRef ref;
  const _Body({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StatusCard(booking: booking),
        const SizedBox(height: 16),
        _PhysioCard(booking: booking),
        const SizedBox(height: 16),
        _SessionInfo(booking: booking),
        const SizedBox(height: 16),
        _PaymentInfo(booking: booking),
        const SizedBox(height: 24),
        if (!booking.isPaid && booking.status != 'cancelled')
          ElevatedButton(
            onPressed: () => context.push('/payment/${booking.id}'),
            child: const Text('Pay Now'),
          ),
        if (booking.canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _cancelDialog(context),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed, side: const BorderSide(color: AppTheme.errorRed)),
            child: const Text('Cancel Booking'),
          ),
        ],
      ]),
    );
  }

  Future<void> _cancelDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if (reason == null) return;
    await ref.read(cancelBookingProvider.notifier).cancel(booking.id, reason: reason);
    if (context.mounted) context.pop();
  }
}

class _StatusCard extends StatelessWidget {
  final BookingDetail booking;
  const _StatusCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _statusStyle(booking.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          Text('${booking.scheduledDate} at ${booking.scheduledTime.substring(0, 5)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ]),
      ]),
    );
  }

  (Color, IconData) _statusStyle(String s) => switch (s) {
    'confirmed' => (AppTheme.successGreen, Icons.check_circle),
    'pending'   => (AppTheme.warningAmber, Icons.schedule),
    'completed' => (AppTheme.primaryBlue, Icons.done_all),
    'cancelled' => (AppTheme.errorRed, Icons.cancel),
    _           => (AppTheme.textSecondary, Icons.info),
  };
}

class _PhysioCard extends StatelessWidget {
  final BookingDetail booking;
  const _PhysioCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: booking.physioAvatar != null ? NetworkImage(booking.physioAvatar!) : null,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: booking.physioAvatar == null
                ? Text((booking.physioName ?? 'P')[0], style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 20))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(booking.physioName ?? 'Physiotherapist',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (booking.physioQualification != null)
                Text(booking.physioQualification!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              if (booking.physioRating != null)
                Row(children: [
                  const Icon(Icons.star, size: 13, color: Colors.amber),
                  Text(' ${booking.physioRating!.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
            ]),
          ),
          if (booking.physioPhone != null)
            IconButton(
              icon: const Icon(Icons.phone, color: AppTheme.successGreen),
              onPressed: () => launchUrl(Uri.parse('tel:${booking.physioPhone}')),
            ),
        ]),
      ),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  final BookingDetail booking;
  const _SessionInfo({required this.booking});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Session Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const Divider(height: 16),
        _Row('Type', booking.bookingType.replaceAll('_', ' ')),
        _Row('Date', booking.scheduledDate),
        _Row('Time', booking.scheduledTime.substring(0, 5)),
      ]),
    ),
  );
}

class _PaymentInfo extends StatelessWidget {
  final BookingDetail booking;
  const _PaymentInfo({required this.booking});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const Divider(height: 16),
        _Row('Session Fee', '₹${booking.sessionFee.toStringAsFixed(0)}'),
        _Row('Platform Fee', '₹${booking.platformFee.toStringAsFixed(0)}'),
        const Divider(height: 12),
        _Row('Total', '₹${booking.totalAmount.toStringAsFixed(0)}', bold: true),
        _Row('Status', booking.paymentStatus.toUpperCase(),
          valueColor: booking.isPaid ? AppTheme.successGreen : AppTheme.warningAmber),
      ]),
    ),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: valueColor ?? AppTheme.textPrimary,
        )),
      ],
    ),
  );
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cancel Booking'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Are you sure? This action cannot be undone.'),
      const SizedBox(height: 12),
      TextField(
        controller: _ctrl,
        decoration: const InputDecoration(hintText: 'Reason (optional)'),
        maxLines: 2,
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Booking')),
      TextButton(
        onPressed: () => Navigator.pop(context, _ctrl.text.isEmpty ? 'Cancelled by patient' : _ctrl.text),
        style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
        child: const Text('Cancel Booking'),
      ),
    ],
  );
}
