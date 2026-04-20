import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/patients_provider.dart';
import '../models/patient_model.dart';
import '../../../core/theme/app_theme.dart';

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Patients')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(patientsProvider.future),
        child: patientsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (patients) => patients.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  itemBuilder: (_, i) => _PatientTile(patient: patients[i]),
                ),
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientSummary patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/patients/${patient.id}'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
          backgroundImage: patient.profilePhotoUrl != null
              ? NetworkImage(patient.profilePhotoUrl!) : null,
          child: patient.profilePhotoUrl == null
              ? Text(patient.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen))
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patient.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          if (patient.condition != null)
            Text(patient.condition!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          if (patient.lastVisit != null)
            Text('Last visit: ${patient.lastVisit}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${patient.totalSessions}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
          const Text('sessions', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ]),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
      SizedBox(height: 12),
      Text('No patients yet', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
    ]),
  );
}
