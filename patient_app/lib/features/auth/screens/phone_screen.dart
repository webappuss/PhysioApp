import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final phone = _ctrl.text.trim();
    await ref.read(otpSendProvider.notifier).sendOtp(phone);
    if (!mounted) return;
    final state = ref.read(otpSendProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppTheme.errorRed),
      );
    } else {
      context.push('/auth/otp', extra: phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpSendProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Image.asset('assets/images/logo.png', height: 40),
                const SizedBox(height: 48),
                const Text('Welcome to\nPhysioConnect',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.2)),
                const SizedBox(height: 8),
                const Text('India\'s trusted physiotherapy platform.\nEnter your mobile number to continue.',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5)),
                const SizedBox(height: 40),
                const Text('Mobile Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ctrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  decoration: InputDecoration(
                    prefixText: '+91  ',
                    prefixStyle: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    hintText: '98765 43210',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your mobile number';
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return 'Enter a valid 10-digit Indian mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send OTP'),
                ),
                const Spacer(),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'By continuing, you agree to our ',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      children: [
                        TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.primaryBlue)),
                        const TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.primaryBlue)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
