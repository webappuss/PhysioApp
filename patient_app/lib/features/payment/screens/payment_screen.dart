import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data/payment_repository.dart';
import '../../booking/providers/booking_provider.dart';
import '../../../core/theme/app_theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Razorpay _razorpay;
  bool _loading = false;
  Map<String, dynamic>? _orderData;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
    _loadOrder();
  }

  @override
  void dispose() { _razorpay.clear(); super.dispose(); }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);
    try {
      final order = await ref.read(paymentRepositoryProvider).createOrder(widget.bookingId);
      setState(() { _orderData = order; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _openRazorpay() {
    if (_orderData == null) return;
    final bookingAsync = ref.read(bookingDetailProvider(widget.bookingId));
    final patientPhone  = ''; // pulled from auth state in real app

    final options = {
      'key':         _orderData!['key_id'],
      'amount':      _orderData!['amount_paise'],
      'currency':    'INR',
      'order_id':    _orderData!['razorpay_order_id'],
      'name':        'PhysioConnect',
      'description': 'Physiotherapy Session',
      'prefill':     {'contact': patientPhone},
      'theme':       {'color': '#1A6FD4'},
    };
    _razorpay.open(options);
  }

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    setState(() => _loading = true);
    try {
      await ref.read(paymentRepositoryProvider).verifyPayment(
        orderId:   response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! 🎉'), backgroundColor: AppTheme.successGreen),
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

  void _onError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? 'Payment failed. Please try again.'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _onWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orderData == null
              ? const Center(child: Text('Failed to load order'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(children: [
                        _Row('Amount', '₹${(_orderData!['amount'] as num).toStringAsFixed(0)}'),
                        _Row('Currency', 'INR'),
                        _Row('Order ID', _orderData!['razorpay_order_id'] as String),
                      ]),
                    ),
                    const Spacer(),
                    const Text(
                      '🔒 Secured by Razorpay. We accept UPI, cards, net banking & wallets.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openRazorpay,
                      child: Text('Pay ₹${(_orderData!['amount'] as num).toStringAsFixed(0)}'),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
