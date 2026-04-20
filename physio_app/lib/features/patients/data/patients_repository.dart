import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/patient_model.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository(ref.watch(apiClientProvider));
});

class PatientsRepository {
  final ApiClient _api;
  PatientsRepository(this._api);

  Future<List<PatientSummary>> getPatients() async {
    final res = await _api.get(ApiEndpoints.physioPatients);
    return (res.data['data'] as List? ?? [])
        .map((e) => PatientSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getPatientDetail(int id) async {
    final res = await _api.get(ApiEndpoints.patientDetail(id));
    return res.data['data'] as Map<String, dynamic>;
  }
}
