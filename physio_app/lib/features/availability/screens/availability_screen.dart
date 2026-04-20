import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/availability_provider.dart';
import '../models/availability_model.dart';
import '../../../core/theme/app_theme.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  List<AvailabilitySlot>? _slots;
  bool _dirty = false;

  static const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  @override
  Widget build(BuildContext context) {
    final asyncSlots = ref.watch(availabilityProvider);
    final saving = ref.watch(availabilityNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: saving ? null : _save,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: asyncSlots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (serverSlots) {
          _slots ??= _buildSlots(serverSlots);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Set your available hours for each day. Patients can only book during these times.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ..._slots!.map((slot) => _DayTile(
                slot: slot,
                onChanged: (updated) {
                  setState(() {
                    final idx = _slots!.indexWhere((s) => s.dayOfWeek == slot.dayOfWeek);
                    if (idx >= 0) _slots![idx] = updated;
                    _dirty = true;
                  });
                },
              )),
            ],
          );
        },
      ),
    );
  }

  List<AvailabilitySlot> _buildSlots(List<AvailabilitySlot> server) {
    return _days.map((day) {
      return server.firstWhere((s) => s.dayOfWeek == day,
          orElse: () => AvailabilitySlot(
            dayOfWeek: day,
            isAvailable: false,
            startTime: '09:00',
            endTime: '18:00',
            slotDurationMinutes: 60,
          ));
    }).toList();
  }

  Future<void> _save() async {
    if (_slots == null) return;
    await ref.read(availabilityNotifierProvider.notifier).save(_slots!);
    final state = ref.read(availabilityNotifierProvider);
    if (mounted) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString()), backgroundColor: AppTheme.errorRed),
        );
      } else {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved'), backgroundColor: AppTheme.successGreen),
        );
      }
    }
  }
}

class _DayTile extends StatelessWidget {
  final AvailabilitySlot slot;
  final ValueChanged<AvailabilitySlot> onChanged;
  const _DayTile({required this.slot, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: slot.isAvailable ? AppTheme.primaryGreen.withOpacity(0.4) : AppTheme.divider,
        ),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              slot.dayOfWeek[0].toUpperCase() + slot.dayOfWeek.substring(1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: slot.isAvailable ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            Switch(
              value: slot.isAvailable,
              activeColor: AppTheme.primaryGreen,
              onChanged: (v) => onChanged(slot.copyWith(isAvailable: v)),
            ),
          ],
        ),
        if (slot.isAvailable) ...[
          const Divider(height: 20),
          Row(children: [
            Expanded(child: _TimePicker(
              label: 'Start',
              time: slot.startTime,
              onChanged: (t) => onChanged(slot.copyWith(startTime: t)),
            )),
            const SizedBox(width: 16),
            Expanded(child: _TimePicker(
              label: 'End',
              time: slot.endTime,
              onChanged: (t) => onChanged(slot.copyWith(endTime: t)),
            )),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Duration', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                DropdownButton<int>(
                  value: slot.slotDurationMinutes,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 30,  child: Text('30 min')),
                    DropdownMenuItem(value: 45,  child: Text('45 min')),
                    DropdownMenuItem(value: 60,  child: Text('60 min')),
                    DropdownMenuItem(value: 90,  child: Text('90 min')),
                  ],
                  onChanged: (v) => onChanged(slot.copyWith(slotDurationMinutes: v)),
                ),
              ],
            )),
          ]),
        ],
      ]),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label, time;
  final ValueChanged<String> onChanged;
  const _TimePicker({required this.label, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final parts = time.split(':');
    final tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: tod);
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}
