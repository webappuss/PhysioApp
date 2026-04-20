import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/session_repository.dart';
import '../../../core/theme/app_theme.dart';

class SoapNotesScreen extends ConsumerStatefulWidget {
  final int bookingId;
  const SoapNotesScreen({super.key, required this.bookingId});

  @override
  ConsumerState<SoapNotesScreen> createState() => _SoapNotesScreenState();
}

class _SoapNotesScreenState extends ConsumerState<SoapNotesScreen> {
  final _sCtrl = TextEditingController(); // Subjective
  final _oCtrl = TextEditingController(); // Objective
  final _aCtrl = TextEditingController(); // Assessment
  final _pCtrl = TextEditingController(); // Plan
  final _hCtrl = TextEditingController(); // Homework
  bool _loading = false;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    setState(() => _loading = true);
    try {
      final id = await ref.read(sessionRepositoryProvider).createSession(widget.bookingId);
      setState(() { _sessionId = id; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  void dispose() {
    _sCtrl.dispose(); _oCtrl.dispose(); _aCtrl.dispose();
    _pCtrl.dispose(); _hCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_sessionId == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(sessionRepositoryProvider).saveSoapNotes(_sessionId!, {
        if (_sCtrl.text.isNotEmpty) 'soap_subjective':      _sCtrl.text,
        if (_oCtrl.text.isNotEmpty) 'soap_objective':       _oCtrl.text,
        if (_aCtrl.text.isNotEmpty) 'soap_assessment':      _aCtrl.text,
        if (_pCtrl.text.isNotEmpty) 'soap_plan':            _pCtrl.text,
        if (_hCtrl.text.isNotEmpty) 'homework_instructions':_hCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOAP notes saved'), backgroundColor: AppTheme.successGreen),
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
      appBar: AppBar(
        title: const Text('SOAP Notes'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading && _sessionId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SOAP Notes — Booking #',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                _SoapSection(
                  letter: 'S',
                  title: 'Subjective',
                  subtitle: "Patient's complaints, symptoms, history",
                  controller: _sCtrl,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 16),
                _SoapSection(
                  letter: 'O',
                  title: 'Objective',
                  subtitle: 'Measurable findings, tests, observations',
                  controller: _oCtrl,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                _SoapSection(
                  letter: 'A',
                  title: 'Assessment',
                  subtitle: 'Diagnosis, interpretation of findings',
                  controller: _aCtrl,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                _SoapSection(
                  letter: 'P',
                  title: 'Plan',
                  subtitle: 'Treatment plan, follow-up, referrals',
                  controller: _pCtrl,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 16),
                _SoapSection(
                  letter: 'HW',
                  title: 'Home Exercise Program',
                  subtitle: 'Instructions and exercises for patient',
                  controller: _hCtrl,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save SOAP Notes'),
                ),
              ]),
            ),
    );
  }
}

class _SoapSection extends StatelessWidget {
  final String letter, title, subtitle;
  final TextEditingController controller;
  final Color color;

  const _SoapSection({
    required this.letter,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter $title notes...',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ]),
    );
  }
}
