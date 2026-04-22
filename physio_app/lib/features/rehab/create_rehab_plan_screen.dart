import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

class CreateRehabPlanScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;
  const CreateRehabPlanScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<CreateRehabPlanScreen> createState() => _CreateRehabPlanScreenState();
}

class _CreateRehabPlanScreenState extends ConsumerState<CreateRehabPlanScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _diagCtrl    = TextEditingController();
  final _notesCtrl   = TextEditingController();
  int   _totalPhases = 3;
  bool  _loading     = false;
  String? _error;

  // Exercises to add (fetched from backend library)
  List<Map<String, dynamic>> _allExercises = [];
  final Set<int> _selectedIds = {};
  bool _loadingExercises = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.exercises);
      setState(() {
        _allExercises    = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        _loadingExercises = false;
      });
    } catch (_) {
      setState(() => _loadingExercises = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(apiClientProvider);

      // 1. Create the plan
      final planRes = await api.post(ApiEndpoints.rehabPlans, data: {
        'patient_id':   widget.patientId,
        'title':        _titleCtrl.text.trim(),
        'diagnosis':    _diagCtrl.text.trim().isEmpty ? null : _diagCtrl.text.trim(),
        'total_phases': _totalPhases,
        'notes':        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });
      final planId = planRes.data['data']['id'] as int;

      // 2. Add selected exercises to phase 1
      for (final exId in _selectedIds) {
        await api.post(ApiEndpoints.rehabPlanAddExercise(planId), data: {
          'exercise_id': exId,
          'phase':       1,
          'week_number': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rehab plan created successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _diagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Create Rehab Plan'),
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.person_outline, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 8),
                Text('For: ${widget.patientName}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
              ]),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Plan Details',
              child: Column(children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _dec('Plan Title', hint: 'e.g. Post-ACL Reconstruction Rehab'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diagCtrl,
                  decoration: _dec('Diagnosis / Condition', hint: 'e.g. ACL tear, Rotator cuff injury'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Total Phases:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _PhaseCounter(
                    value: _totalPhases,
                    onDecrement: () { if (_totalPhases > 1) setState(() => _totalPhases--); },
                    onIncrement: () { if (_totalPhases < 6) setState(() => _totalPhases++); },
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: _dec('Clinical Notes (optional)'),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Phase 1 Exercises',
              trailing: _selectedIds.isNotEmpty
                  ? Text('${_selectedIds.length} selected',
                      style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13))
                  : null,
              child: _loadingExercises
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ))
                  : _allExercises.isEmpty
                      ? const Text('No exercises in library', style: TextStyle(color: Colors.grey))
                      : Column(
                          children: _allExercises.map((ex) {
                            final id    = ex['id'] as int;
                            final title = ex['title'] as String? ?? '';
                            final cat   = ex['category'] as String? ?? '';
                            final diff  = ex['difficulty'] as String? ?? '';
                            final selected = _selectedIds.contains(id);

                            return CheckboxListTile(
                              value: selected,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppTheme.primaryGreen,
                              title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text('$cat · $diff',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              onChanged: (v) => setState(() {
                                if (v == true) _selectedIds.add(id); else _selectedIds.remove(id);
                              }),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Plan',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PhaseCounter extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _PhaseCounter({required this.value, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        onPressed: onDecrement,
        icon: const Icon(Icons.remove_circle_outline),
        color: AppTheme.primaryGreen,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      Container(
        width: 36,
        alignment: Alignment.center,
        child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      IconButton(
        onPressed: onIncrement,
        icon: const Icon(Icons.add_circle_outline),
        color: AppTheme.primaryGreen,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    ]);
  }
}
