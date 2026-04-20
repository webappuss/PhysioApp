import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/patients_provider.dart';
import '../../../core/theme/app_theme.dart';

class PatientDetailScreen extends ConsumerWidget {
  final int patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(patientDetailProvider(patientId));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
              const SizedBox(height: 12),
              Text('$e', style: TextStyle(color: AppTheme.textLight)),
              TextButton(
                onPressed: () => ref.invalidate(patientDetailProvider(patientId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => _DetailBody(data: data),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DetailBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final patient  = data['patient']  as Map<String, dynamic>? ?? {};
    final profile  = data['profile']  as Map<String, dynamic>? ?? {};
    final bookings = data['bookings'] as List?  ?? [];
    final sessions = data['sessions'] as List?  ?? [];
    final rehabPlan = data['rehab_plan'] as Map<String, dynamic>?;

    return CustomScrollView(
      slivers: [
        _Header(patient: patient, profile: profile),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (profile.isNotEmpty) _MedicalInfoCard(profile: profile),
              const SizedBox(height: 16),
              if (rehabPlan != null) _ActiveRehabCard(plan: rehabPlan),
              if (rehabPlan != null) const SizedBox(height: 16),
              _SessionHistoryCard(sessions: sessions),
              const SizedBox(height: 16),
              _BookingHistoryCard(bookings: bookings),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic> profile;
  const _Header({required this.patient, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name      = patient['name'] as String? ?? 'Patient';
    final phone     = patient['phone'] as String? ?? '';
    final avatar    = patient['avatar_url'] as String?;
    final totalSess = (profile['total_sessions'] as num?)?.toInt() ?? 0;
    final age       = profile['age'] as int?;
    final gender    = profile['gender'] as String?;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen, const Color(0xFF00695C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (age != null) _Pill('$age yrs'),
                            if (gender != null) _Pill(gender),
                            _Pill('$totalSess sessions'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _MedicalInfoCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _MedicalInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final condition     = profile['primary_condition'] as String?;
    final surgeryHx     = profile['surgery_history'] as String?;
    final allergies     = profile['allergies'] as String?;
    final currentMeds   = profile['current_medications'] as String?;
    final bloodGroup    = profile['blood_group'] as String?;
    final emergencyName = profile['emergency_contact_name'] as String?;
    final emergencyPhone= profile['emergency_contact_phone'] as String?;

    return _Card(
      title: 'Medical Information',
      icon: Icons.medical_information_outlined,
      child: Column(
        children: [
          if (condition != null)    _InfoRow('Condition',   condition),
          if (bloodGroup != null)   _InfoRow('Blood Group', bloodGroup),
          if (surgeryHx != null)    _InfoRow('Surgery History', surgeryHx),
          if (allergies != null)    _InfoRow('Allergies',   allergies),
          if (currentMeds != null)  _InfoRow('Medications', currentMeds),
          if (emergencyName != null)
            _InfoRow('Emergency Contact', '$emergencyName${emergencyPhone != null ? ' · $emergencyPhone' : ''}'),
        ],
      ),
    );
  }
}

class _ActiveRehabCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _ActiveRehabCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final title    = plan['title'] as String? ?? 'Rehab Plan';
    final phase    = plan['current_phase'] as int? ?? 1;
    final total    = plan['total_phases'] as int? ?? 1;
    final progress = phase / total;

    return _Card(
      title: 'Active Rehab Plan',
      icon: Icons.fitness_center_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.bgLight,
                    color: AppTheme.primaryGreen,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Phase $phase/$total',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final List sessions;
  const _SessionHistoryCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Session History',
      icon: Icons.history_outlined,
      child: sessions.isEmpty
          ? Text('No sessions yet.', style: TextStyle(color: AppTheme.textLight))
          : Column(
              children: sessions.take(5).map((s) {
                final session  = s as Map<String, dynamic>;
                final date     = session['created_at'] as String?;
                final duration = session['duration_mins'] as int?;
                final painEnd  = session['pain_at_end'] as num?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_outline, size: 18, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(date)) : '—',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (duration != null || painEnd != null)
                              Text(
                                [
                                  if (duration != null) '${duration}min',
                                  if (painEnd != null) 'Pain: ${painEnd.toInt()}/10',
                                ].join(' · '),
                                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final List bookings;
  const _BookingHistoryCard({required this.bookings});

  Color _statusColor(String status) => switch (status) {
        'completed'  => const Color(0xFF4CAF50),
        'cancelled'  => AppTheme.errorRed,
        'confirmed'  => AppTheme.primaryGreen,
        _            => AppTheme.textLight,
      };

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Booking History',
      icon: Icons.calendar_month_outlined,
      child: bookings.isEmpty
          ? Text('No bookings yet.', style: TextStyle(color: AppTheme.textLight))
          : Column(
              children: bookings.take(5).map((b) {
                final booking = b as Map<String, dynamic>;
                final date    = booking['scheduled_date'] as String?;
                final status  = booking['status'] as String? ?? '';
                final id      = booking['id'] as int?;

                return GestureDetector(
                  onTap: id != null ? () => context.push('/bookings/$id') : null,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            date ?? '—',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
