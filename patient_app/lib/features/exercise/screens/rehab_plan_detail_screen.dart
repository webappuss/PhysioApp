import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise_model.dart';

class RehabPlanDetailScreen extends ConsumerWidget {
  final int planId;
  const RehabPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(rehabPlanProvider(planId));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plan) => _PlanBody(plan: plan),
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  final RehabPlan plan;
  const _PlanBody({required this.plan});

  @override
  Widget build(BuildContext context) {
    final exercises = plan.currentExercises;

    return CustomScrollView(
      slivers: [
        _Header(plan: plan),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ExerciseItem(
                item: exercises[i],
                planId: plan.id,
                index: i + 1,
              ),
              childCount: exercises.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final RehabPlan plan;
  const _Header({required this.plan});

  @override
  Widget build(BuildContext context) {
    final completedCount = plan.currentExercises.where((e) => e.isCompleted).length;
    final totalCount = plan.currentExercises.length;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.7)],
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
                  Text(plan.title,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  if (plan.diagnosis != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(plan.diagnosis!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatPill(label: 'Phase ${plan.currentPhase}/${plan.totalPhases}',
                          icon: Icons.layers_outlined),
                      const SizedBox(width: 8),
                      _StatPill(label: '$completedCount/$totalCount done',
                          icon: Icons.check_circle_outline),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ExerciseItem extends ConsumerWidget {
  final RehabPlanExercise item;
  final int planId;
  final int index;
  const _ExerciseItem({required this.item, required this.planId, required this.index});

  void _showAiModifySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _AiModifySheet(item: item, planId: planId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completeAsync = ref.watch(exerciseCompleteProvider);
    final isLoading = completeAsync.isLoading;

    return GestureDetector(
      onLongPress: item.isCompleted ? null : () => _showAiModifySheet(context, ref),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: item.isCompleted ? const Color(0xFFE8F5E9) : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isCompleted ? const Color(0xFF4CAF50).withOpacity(0.4) : Colors.transparent,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _ExerciseNumber(number: index, completed: item.isCompleted),
        title: Text(
          item.exercise.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Tag('${item.exercise.sets} sets × ${item.exercise.reps} reps'),
              _Tag('${item.exercise.durationSec}s'),
              _Tag(item.exercise.difficulty),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              color: AppTheme.textLight,
              onPressed: () => context.push('/exercises/${item.exercise.id}', extra: item.exercise),
            ),
            if (!item.isCompleted)
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => ref
                        .read(exerciseCompleteProvider.notifier)
                        .complete(item.id, planId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Done',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              )
            else
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
          ],
        ),
      ),
      ),
    );
  }
}

class _ExerciseNumber extends StatelessWidget {
  final int number;
  final bool completed;
  const _ExerciseNumber({required this.number, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: completed ? const Color(0xFF4CAF50) : AppTheme.primaryBlue.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '$number',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
    );
  }
}

class _AiModifySheet extends ConsumerStatefulWidget {
  final RehabPlanExercise item;
  final int planId;
  const _AiModifySheet({required this.item, required this.planId});

  @override
  ConsumerState<_AiModifySheet> createState() => _AiModifySheetState();
}

class _AiModifySheetState extends ConsumerState<_AiModifySheet> {
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Exercise? _modified;

  static const _suggestions = [
    'Too painful for me currently',
    'I don\'t have the equipment',
    'Exercise is too easy, make it harder',
    'I have a previous injury in this area',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) return;

    setState(() { _loading = true; _error = null; });
    try {
      final modified = await ref.read(exerciseRepositoryProvider).aiModifyExercise(
        widget.item.id, reason,
      );
      setState(() { _modified = modified; });
      ref.invalidate(rehabPlanProvider(widget.planId));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 10),
                const Text('AI Exercise Modification',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Modifying: ${widget.item.exercise.title}',
                style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
            const SizedBox(height: 16),

            if (_modified != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                      const SizedBox(width: 8),
                      const Text('Exercise Modified!',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                    ]),
                    const SizedBox(height: 8),
                    Text('New exercise: ${_modified!.title}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${_modified!.sets} sets × ${_modified!.reps} reps',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              // Suggestion chips
              const Text('Common reasons:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestions.map((s) => GestureDetector(
                  onTap: () => _reasonCtrl.text = s,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 12)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for modification',
                  hintText: 'Describe why this exercise doesn\'t work for you…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Modify with AI', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
