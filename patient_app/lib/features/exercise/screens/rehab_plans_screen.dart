import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise_model.dart';

class RehabPlansScreen extends ConsumerWidget {
  const RehabPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(myRehabPlansProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('My Rehab Plans'),
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load plans', style: TextStyle(color: AppTheme.textLight)),
              TextButton(
                onPressed: () => ref.invalidate(myRehabPlansProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (plans) => plans.isEmpty
            ? _EmptyState()
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myRehabPlansProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  itemBuilder: (context, i) => _PlanCard(plan: plans[i]),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No rehab plans yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Your physiotherapist will assign\nexercise plans after your session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final RehabPlan plan;
  const _PlanCard({required this.plan});

  Color get _statusColor => switch (plan.status) {
        'active'    => AppTheme.primaryBlue,
        'completed' => const Color(0xFF4CAF50),
        _           => AppTheme.textLight,
      };

  @override
  Widget build(BuildContext context) {
    final progress = plan.exercises.isEmpty
        ? 0.0
        : plan.exercises.where((e) => e.isCompleted).length / plan.exercises.length;

    return GestureDetector(
      onTap: () => context.push('/rehab-plans/${plan.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.status.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor),
                    ),
                  ),
                ],
              ),
              if (plan.diagnosis != null) ...[
                const SizedBox(height: 4),
                Text(plan.diagnosis!, style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(icon: Icons.layers_outlined, label: 'Phase ${plan.currentPhase}/${plan.totalPhases}'),
                  const SizedBox(width: 8),
                  _InfoChip(icon: Icons.fitness_center_outlined, label: '${plan.exercises.length} exercises'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.bgLight,
                        color: AppTheme.primaryBlue,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ],
    );
  }
}
