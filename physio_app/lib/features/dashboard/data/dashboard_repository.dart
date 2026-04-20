import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardRepository {
  final ApiClient _api;
  DashboardRepository(this._api);

  Future<PhysioDashboard> getDashboard() async {
    final res = await _api.get(ApiEndpoints.physioDashboard);
    return PhysioDashboard.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
