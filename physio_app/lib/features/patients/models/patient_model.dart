class PatientSummary {
  final int id;
  final String name;
  final String? phone;
  final String? profilePhotoUrl;
  final int totalSessions;
  final String? lastVisit;
  final String? condition;

  const PatientSummary({
    required this.id,
    required this.name,
    this.phone,
    this.profilePhotoUrl,
    required this.totalSessions,
    this.lastVisit,
    this.condition,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> j) => PatientSummary(
    id:            j['id'] as int,
    name:          j['name'] as String? ?? 'Patient',
    phone:         j['phone'] as String?,
    profilePhotoUrl: j['profile_photo_url'] as String?,
    totalSessions: (j['total_sessions'] as num?)?.toInt() ?? 0,
    lastVisit:     j['last_visit'] as String?,
    condition:     j['condition'] as String?,
  );
}
