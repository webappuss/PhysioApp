import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scores_provider.dart';
import '../models/score_model.dart';

class ScoresScreen extends ConsumerWidget {
  const ScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(scoresProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Outcome Scores'),
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRecordSheet(context, ref),
          ),
        ],
      ),
      body: scoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', style: TextStyle(color: AppTheme.textLight)),
              TextButton(onPressed: () => ref.invalidate(scoresProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (scores) => scores.isEmpty
            ? _EmptyState(onAdd: () => _showRecordSheet(context, ref))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(scoresProvider.future),
                child: _ScoresList(scores: scores),
              ),
      ),
    );
  }

  void _showRecordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _RecordScoreSheet(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text('No scores recorded yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Track your recovery progress\nby recording outcome scores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textLight)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Record Score'),
          ),
        ],
      ),
    );
  }
}

class _ScoresList extends StatelessWidget {
  final List<OutcomeScore> scores;
  const _ScoresList({required this.scores});

  @override
  Widget build(BuildContext context) {
    // Group by scale
    final grouped = <String, List<OutcomeScore>>{};
    for (final s in scores) {
      grouped.putIfAbsent(s.scaleCode, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in grouped.entries) ...[
          _ScaleGroup(scaleCode: entry.key, scores: entry.value),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ScaleGroup extends StatelessWidget {
  final String scaleCode;
  final List<OutcomeScore> scores;
  const _ScaleGroup({required this.scaleCode, required this.scores});

  @override
  Widget build(BuildContext context) {
    final latest = scores.first;
    final trend  = scores.length > 1 ? scores[0].totalScore - scores[1].totalScore : 0;

    return GestureDetector(
      onTap: () => context.push('/scores/$scaleCode'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(latest.scaleName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        'Last recorded: ${DateFormat('dd MMM yyyy').format(latest.sessionDate)}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${latest.totalScore}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    if (trend != 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trend > 0 ? Icons.trending_up : Icons.trending_down,
                            size: 14,
                            color: trend > 0 ? const Color(0xFF4CAF50) : AppTheme.errorRed,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${trend > 0 ? '+' : ''}$trend',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: trend > 0 ? const Color(0xFF4CAF50) : AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                latest.interpretation,
                style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.history_outlined, size: 13, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text('${scores.length} record${scores.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 16, color: Color(0xFFBBBBBB)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordScoreSheet extends ConsumerStatefulWidget {
  const _RecordScoreSheet();

  @override
  ConsumerState<_RecordScoreSheet> createState() => _RecordScoreSheetState();
}

class _RecordScoreSheetState extends ConsumerState<_RecordScoreSheet> {
  OutcomeScale? _selectedScale;
  double _score = 0;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _interpret(String code, double score) {
    return switch (code) {
      'VAS' => score <= 3 ? 'Mild pain' : score <= 6 ? 'Moderate pain' : 'Severe pain',
      'KOOS' || 'PSFS' => score >= 70 ? 'Good function' : score >= 40 ? 'Moderate function' : 'Poor function',
      'DASH' || 'NDI' => score <= 20 ? 'Minimal disability' : score <= 40 ? 'Moderate disability' : 'Severe disability',
      _ => 'Recorded',
    };
  }

  Future<void> _submit() async {
    if (_selectedScale == null) return;
    await ref.read(recordScoreProvider.notifier).record(
          scaleCode:     _selectedScale!.code,
          totalScore:    _score.round(),
          interpretation: _interpret(_selectedScale!.code, _score),
          notes:         _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final recordAsync = ref.watch(recordScoreProvider);
    final isLoading   = recordAsync.isLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
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
            const Text('Record Outcome Score',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Scale picker
            DropdownButtonFormField<OutcomeScale>(
              value: _selectedScale,
              decoration: InputDecoration(
                labelText: 'Outcome Scale',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: kOutcomeScales
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() { _selectedScale = v; _score = (v?.minScore ?? 0).toDouble(); }),
            ),
            const SizedBox(height: 16),

            if (_selectedScale != null) ...[
              Text(_selectedScale!.description,
                  style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Score:', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    _score.round().toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _score,
                min:   _selectedScale!.minScore.toDouble(),
                max:   _selectedScale!.maxScore.toDouble(),
                divisions: _selectedScale!.maxScore - _selectedScale!.minScore,
                activeColor: AppTheme.primaryBlue,
                onChanged: (v) => setState(() => _score = v),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _interpret(_selectedScale!.code, _score),
                  style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
