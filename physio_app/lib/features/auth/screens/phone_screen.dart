import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(otpSendProvider.notifier).sendOtp(_ctrl.text.trim());
    final state = ref.read(otpSendProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    if (mounted) context.push('/auth/otp', extra: _ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(otpSendProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medical_services_outlined, size: 40, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text('Welcome, Physio',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('Enter your registered mobile number to continue',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
              const SizedBox(height: 40),
              TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter mobile number';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _send,
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send OTP'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
