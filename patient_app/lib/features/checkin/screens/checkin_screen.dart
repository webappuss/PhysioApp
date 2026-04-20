import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/checkin_repository.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../../../core/theme/app_theme.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  double _painScore   = 0;
  int    _moodScore   = 5;
  double _sleepHours  = 7;
  int    _energyLevel = 5;
  final  _notesCtrl = TextEditingController();
  bool   _loading = false;

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(checkinRepositoryProvider).submitCheckin(
        painScore: _painScore,
        moodScore: _moodScore,
        sleepHours: _sleepHours,
        energyLevel: _energyLevel,
        notes: _notesCtrl.text,
      );
      ref.invalidate(dashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in recorded! +10 XP 🎉'), backgroundColor: AppTheme.successGreen),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Check-in")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How are you feeling today?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('This helps your physio track your progress',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),

          _ScaleCard(
            emoji: '😣', title: 'Pain Level',
            subtitle: 'How much pain are you in?',
            value: _painScore, min: 0, max: 10, divisions: 10,
            labels: const ['No pain', 'Worst pain'],
            onChanged: (v) => setState(() => _painScore = v),
          ),
          const SizedBox(height: 20),

          _ScaleCard(
            emoji: '😊', title: 'Mood',
            subtitle: 'How is your mood today?',
            value: _moodScore.toDouble(), min: 0, max: 10, divisions: 10,
            labels: const ['Very low', 'Excellent'],
            onChanged: (v) => setState(() => _moodScore = v.round()),
          ),
          const SizedBox(height: 20),

          _ScaleCard(
            emoji: '💤', title: 'Sleep',
            subtitle: 'How many hours did you sleep?',
            value: _sleepHours, min: 0, max: 12, divisions: 24,
            labels: const ['0h', '12h'],
            displayValue: '${_sleepHours.toStringAsFixed(1)}h',
            onChanged: (v) => setState(() => _sleepHours = v),
          ),
          const SizedBox(height: 20),

          _ScaleCard(
            emoji: '⚡', title: 'Energy Level',
            subtitle: 'How energetic do you feel?',
            value: _energyLevel.toDouble(), min: 0, max: 10, divisions: 10,
            labels: const ['Exhausted', 'Full energy'],
            onChanged: (v) => setState(() => _energyLevel = v.round()),
          ),
          const SizedBox(height: 20),

          const Text('Any notes for your physio?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Pain increased after morning walk...',
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Check-in'),
          ),
        ]),
      ),
    );
  }
}

class _ScaleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final double value, min, max;
  final int divisions;
  final List<String> labels;
  final String? displayValue;
  final ValueChanged<double> onChanged;

  const _ScaleCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.value, required this.min, required this.max,
    required this.divisions, required this.labels, required this.onChanged,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(displayValue ?? value.round().toString(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
            ),
          ],
        ),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Slider(
          value: value, min: min, max: max, divisions: divisions,
          activeColor: AppTheme.primaryBlue,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(l, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))).toList(),
        ),
      ]),
    );
  }
}
