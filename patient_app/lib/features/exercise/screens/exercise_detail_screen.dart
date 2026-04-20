import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/exercise_model.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  Color get _difficultyColor => switch (exercise.difficulty) {
        'easy'   => const Color(0xFF4CAF50),
        'medium' => const Color(0xFFFF9800),
        _        => const Color(0xFFF44336),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, const Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Pill(exercise.category),
                            const SizedBox(width: 6),
                            _Pill(exercise.bodyPart),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    _StatCard(label: 'Sets', value: '${exercise.sets}', icon: Icons.repeat),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Reps', value: '${exercise.reps}', icon: Icons.fitness_center),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Rest', value: '${exercise.restSec}s', icon: Icons.timer_outlined),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Time', value: '${exercise.durationSec}s', icon: Icons.hourglass_empty),
                  ],
                ),
                const SizedBox(height: 16),

                // Difficulty badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 14, color: _difficultyColor),
                          const SizedBox(width: 4),
                          Text(
                            exercise.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _difficultyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Equipment
                if (exercise.equipment.isNotEmpty) ...[
                  _SectionHeader('Equipment needed'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: exercise.equipment
                        .map((e) => _EquipmentChip(e))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Instructions
                _SectionHeader('How to perform'),
                const SizedBox(height: 10),
                ...exercise.instructions.asMap().entries.map(
                      (entry) => _InstructionStep(
                        step: entry.key + 1,
                        text: entry.value,
                      ),
                    ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _EquipmentChip extends StatelessWidget {
  final String label;
  const _EquipmentChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int step;
  final String text;
  const _InstructionStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
