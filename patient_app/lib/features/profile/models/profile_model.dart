class PatientProfile {
  final int id;
  final String uuid;
  final String phone;
  final String? email;
  final String? name;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? bloodGroup;
  final String? medicalHistory;
  final String? profilePhotoUrl;
  final int streakDays;
  final int totalXp;
  final int level;
  final int totalSessions;
  final int totalCheckins;

  const PatientProfile({
    required this.id,
    required this.uuid,
    required this.phone,
    this.email,
    this.name,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.bloodGroup,
    this.medicalHistory,
    this.profilePhotoUrl,
    required this.streakDays,
    required this.totalXp,
    required this.level,
    required this.totalSessions,
    required this.totalCheckins,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> j) => PatientProfile(
    id:               j['id'] as int,
    uuid:             j['uuid'] as String,
    phone:            j['phone'] as String,
    email:            j['email'] as String?,
    name:             j['name'] as String?,
    dateOfBirth:      j['date_of_birth'] as String?,
    gender:           j['gender'] as String?,
    address:          j['address'] as String?,
    bloodGroup:       j['blood_group'] as String?,
    medicalHistory:   j['medical_history'] as String?,
    profilePhotoUrl:  j['profile_photo_url'] as String?,
    streakDays:       (j['streak_days'] as num?)?.toInt() ?? 0,
    totalXp:          (j['total_xp'] as num?)?.toInt() ?? 0,
    level:            (j['level'] as num?)?.toInt() ?? 1,
    totalSessions:    (j['total_sessions'] as num?)?.toInt() ?? 0,
    totalCheckins:    (j['total_checkins'] as num?)?.toInt() ?? 0,
  );

  PatientProfile copyWith({
    String? email,
    String? name,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? bloodGroup,
    String? medicalHistory,
  }) => PatientProfile(
    id:              id,
    uuid:            uuid,
    phone:           phone,
    email:           email ?? this.email,
    name:            name ?? this.name,
    dateOfBirth:     dateOfBirth ?? this.dateOfBirth,
    gender:          gender ?? this.gender,
    address:         address ?? this.address,
    bloodGroup:      bloodGroup ?? this.bloodGroup,
    medicalHistory:  medicalHistory ?? this.medicalHistory,
    profilePhotoUrl: profilePhotoUrl,
    streakDays:      streakDays,
    totalXp:         totalXp,
    level:           level,
    totalSessions:   totalSessions,
    totalCheckins:   totalCheckins,
  );
}
