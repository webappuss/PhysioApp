import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

class PaymentRepository {
  final ApiClient _api;
  PaymentRepository(this._api);

  Future<Map<String, dynamic>> createOrder(int bookingId) async {
    final res = await _api.post(ApiEndpoints.createOrder, data: {'booking_id': bookingId});
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String? paymentMethod,
  }) async {
    final res = await _api.post(ApiEndpoints.verifyPayment, data: {
      'razorpay_order_id':   orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature':  signature,
      if (paymentMethod != null) 'payment_method': paymentMethod,
    });
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final res = await _api.get(ApiEndpoints.paymentHistory);
    return (res.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
  }
}
