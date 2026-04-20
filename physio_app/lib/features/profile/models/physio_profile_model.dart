class PhysioProfile {
  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String? bio;
  final List<String> specializations;
  final int experienceYears;
  final double consultationFee;
  final double homeVisitFee;
  final double rating;
  final int totalReviews;
  final int totalSessions;
  final String verificationStatus;
  final String? profilePhotoUrl;
  final String? registrationNumber;

  const PhysioProfile({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.bio,
    required this.specializations,
    required this.experienceYears,
    required this.consultationFee,
    required this.homeVisitFee,
    required this.rating,
    required this.totalReviews,
    required this.totalSessions,
    required this.verificationStatus,
    this.profilePhotoUrl,
    this.registrationNumber,
  });

  factory PhysioProfile.fromJson(Map<String, dynamic> j) => PhysioProfile(
    id:                 j['id'] as int,
    phone:              j['phone'] as String,
    name:               j['name'] as String?,
    email:              j['email'] as String?,
    bio:                j['bio'] as String?,
    specializations:    (j['specializations'] as List? ?? []).cast<String>(),
    experienceYears:    (j['experience_years'] as num?)?.toInt() ?? 0,
    consultationFee:    (j['consultation_fee'] as num?)?.toDouble() ?? 0,
    homeVisitFee:       (j['home_visit_fee'] as num?)?.toDouble() ?? 0,
    rating:             (j['rating'] as num?)?.toDouble() ?? 0,
    totalReviews:       (j['total_reviews'] as num?)?.toInt() ?? 0,
    totalSessions:      (j['total_sessions'] as num?)?.toInt() ?? 0,
    verificationStatus: j['verification_status'] as String? ?? 'pending',
    profilePhotoUrl:    j['profile_photo_url'] as String?,
    registrationNumber: j['registration_number'] as String?,
  );
}
