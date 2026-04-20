import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/patients_repository.dart';
import '../models/patient_model.dart';

final patientsProvider = FutureProvider.autoDispose<List<PatientSummary>>((ref) {
  return ref.watch(patientsRepositoryProvider).getPatients();
});

final patientDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) {
  return ref.watch(patientsRepositoryProvider).getPatientDetail(id);
});
