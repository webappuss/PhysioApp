import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../../discovery/providers/discovery_provider.dart';
import '../../../core/theme/app_theme.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final int physioId;
  const BookingScreen({super.key, required this.physioId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  String _bookingType = 'home_visit';

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(availableSlotsProvider((
      physioId: widget.physioId,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    )));
    final createState = ref.watch(createBookingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionTitle('Session Type'),
          const SizedBox(height: 8),
          Row(children: [
            _TypeCard(
              label: '🏠 Home Visit', value: 'home_visit',
              selected: _bookingType == 'home_visit',
              onTap: () => setState(() => _bookingType = 'home_visit'),
            ),
            const SizedBox(width: 12),
            _TypeCard(
              label: '📱 Video Consult', value: 'video_consult',
              selected: _bookingType == 'video_consult',
              onTap: () => setState(() => _bookingType = 'video_consult'),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionTitle('Select Date'),
          const SizedBox(height: 8),
          _DatePicker(
            selected: _selectedDate,
            onPick: (d) => setState(() { _selectedDate = d; _selectedTime = null; }),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Select Time Slot'),
          const SizedBox(height: 8),
          slotsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
            data: (slots) => slots.isEmpty
                ? const Text('No slots available for this date', style: TextStyle(color: AppTheme.textSecondary))
                : Wrap(
                    spacing: 8, runSpacing: 8,
                    children: slots.map((s) => _SlotChip(
                      time: s,
                      selected: _selectedTime == s,
                      onTap: () => setState(() => _selectedTime = s),
                    )).toList(),
                  ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (_selectedTime == null || createState.isLoading) ? null : _book,
          child: createState.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm Booking'),
        ),
      ),
    );
  }

  Future<void> _book() async {
    final booking = await ref.read(createBookingProvider.notifier).create(
      physioId: widget.physioId,
      bookingType: _bookingType,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      time: _selectedTime!.substring(0, 5),
    );
    if (!mounted) return;
    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created! Awaiting physio confirmation.'), backgroundColor: AppTheme.successGreen),
      );
      context.go('/bookings/${booking.id}');
    } else {
      final err = ref.read(createBookingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err?.toString() ?? 'Failed to book'), backgroundColor: AppTheme.errorRed),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
    Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
}

class _TypeCard extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primaryBlue : AppTheme.divider, width: selected ? 2 : 1),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppTheme.primaryBlue : AppTheme.textPrimary)),
      ),
    ),
  );
}

class _DatePicker extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  const _DatePicker({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected = DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(selected);
          return GestureDetector(
            onTap: () => onPick(d),
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.divider),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(DateFormat('EEE').format(d),
                  style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppTheme.textSecondary)),
                Text('${d.day}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                Text(DateFormat('MMM').format(d),
                  style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppTheme.textSecondary)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String time;
  final bool selected;
  final VoidCallback onTap;
  const _SlotChip({required this.time, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryBlue : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppTheme.primaryBlue : AppTheme.divider),
      ),
      child: Text(time.substring(0, 5),
        style: TextStyle(fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textPrimary)),
    ),
  );
}
