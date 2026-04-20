import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/session_model.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(apiClientProvider));
});

class SessionRepository {
  final ApiClient _api;
  SessionRepository(this._api);

  Future<int> createSession(int bookingId) async {
    final res = await _api.post(ApiEndpoints.sessions, data: {'booking_id': bookingId});
    return (res.data['data']['id'] as num).toInt();
  }

  Future<SoapNotes?> getSoapNotes(int sessionId) async {
    try {
      final res = await _api.get(ApiEndpoints.sessionDetail(sessionId));
      return SoapNotes.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSoapNotes(int sessionId, Map<String, dynamic> data) =>
      _api.post(ApiEndpoints.soapNotes(sessionId), data: data);
}
