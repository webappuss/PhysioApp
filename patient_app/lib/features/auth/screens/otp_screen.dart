import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otp = '';
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); return; }
      setState(() => _seconds--);
    });
  }

  Future<void> _resend() async {
    await ref.read(otpSendProvider.notifier).sendOtp(widget.phone);
    _startTimer();
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    final user = await ref.read(otpVerifyProvider.notifier).verify(widget.phone, _otp);
    if (!mounted) return;
    if (user != null) {
      context.go('/dashboard');
    } else {
      final err = ref.read(otpVerifyProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err?.toString() ?? 'Invalid OTP'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpVerifyProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Enter OTP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text('We sent a 6-digit code to +91 ${widget.phone}',
                style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 52,
                  fieldWidth: 48,
                  activeFillColor: AppTheme.cardWhite,
                  inactiveFillColor: AppTheme.bgLight,
                  selectedFillColor: AppTheme.cardWhite,
                  activeColor: AppTheme.primaryBlue,
                  inactiveColor: AppTheme.divider,
                  selectedColor: AppTheme.primaryBlue,
                ),
                enableActiveFill: true,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (isLoading || _otp.length < 6) ? null : _verify,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Continue'),
              ),
              const SizedBox(height: 24),
              Center(
                child: _seconds > 0
                    ? Text('Resend OTP in ${_seconds}s', style: const TextStyle(color: AppTheme.textSecondary))
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend OTP'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
