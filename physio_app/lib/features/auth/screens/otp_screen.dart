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
  final _ctrl = TextEditingController();
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); return; }
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() { _timer?.cancel(); _ctrl.dispose(); super.dispose(); }

  Future<void> _verify(String otp) async {
    if (otp.length < 6) return;
    final user = await ref.read(otpVerifyProvider.notifier).verify(widget.phone, otp);
    if (!mounted) return;
    final state = ref.read(otpVerifyProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: AppTheme.errorRed),
      );
      _ctrl.clear();
      return;
    }
    if (user != null) context.go('/dashboard');
  }

  Future<void> _resend() async {
    await ref.read(otpSendProvider.notifier).sendOtp(widget.phone);
    if (mounted) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(otpVerifyProvider).isLoading;
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          const Text('Enter OTP',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Sent to +91 ${widget.phone}',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 40),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _ctrl,
            keyboardType: TextInputType.number,
            animationType: AnimationType.scale,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 54,
              fieldWidth: 46,
              activeFillColor: AppTheme.cardWhite,
              selectedFillColor: AppTheme.cardWhite,
              inactiveFillColor: AppTheme.cardWhite,
              activeColor: AppTheme.primaryGreen,
              selectedColor: AppTheme.primaryGreen,
              inactiveColor: AppTheme.divider,
            ),
            enableActiveFill: true,
            onCompleted: (v) => _verify(v),
            onChanged: (_) {},
          ),
          const SizedBox(height: 24),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: _seconds > 0
                  ? Text('Resend OTP in ${_seconds}s',
                      style: const TextStyle(color: AppTheme.textSecondary))
                  : TextButton(
                      onPressed: _resend,
                      child: const Text('Resend OTP', style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
            ),
        ]),
      ),
    );
  }
}
