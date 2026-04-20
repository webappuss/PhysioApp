class PhysioCard {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? qualification;
  final List<String> specializations;
  final int? yearsExperience;
  final double? homeVisitCharge;
  final double? videoConsultCharge;
  final double rating;
  final int totalReviews;
  final int totalSessions;
  final double? distanceKm;

  const PhysioCard({
    required this.id, required this.name, this.avatarUrl, this.qualification,
    required this.specializations, this.yearsExperience, this.homeVisitCharge,
    this.videoConsultCharge, required this.rating, required this.totalReviews,
    required this.totalSessions, this.distanceKm,
  });

  factory PhysioCard.fromJson(Map<String, dynamic> j) {
    List<String> specs = [];
    final raw = j['specializations'];
    if (raw is List) specs = raw.cast<String>();
    else if (raw is String && raw.isNotEmpty) {
      try { specs = (raw as dynamic) is List ? (raw as List).cast<String>() : [raw]; } catch (_) {}
    }
    return PhysioCard(
      id: j['id'] as int,
      name: j['name'] as String,
      avatarUrl: j['avatar_url'] as String?,
      qualification: j['qualification'] as String?,
      specializations: specs,
      yearsExperience: j['years_experience'] as int?,
      homeVisitCharge: (j['home_visit_charge'] as num?)?.toDouble(),
      videoConsultCharge: (j['video_consult_charge'] as num?)?.toDouble(),
      rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: j['total_reviews'] as int? ?? 0,
      totalSessions: j['total_sessions'] as int? ?? 0,
      distanceKm: (j['distance_km'] as num?)?.toDouble(),
    );
  }
}

class PhysioSearchResult {
  final List<PhysioCard> physios;
  final int currentPage;
  final int lastPage;
  final int total;

  const PhysioSearchResult({
    required this.physios, required this.currentPage,
    required this.lastPage, required this.total,
  });

  factory PhysioSearchResult.fromJson(Map<String, dynamic> j) => PhysioSearchResult(
    physios: (j['data'] as List? ?? []).map((e) => PhysioCard.fromJson(e as Map<String, dynamic>)).toList(),
    currentPage: (j['pagination'] as Map?)?['current_page'] as int? ?? 1,
    lastPage: (j['pagination'] as Map?)?['last_page'] as int? ?? 1,
    total: (j['pagination'] as Map?)?['total'] as int? ?? 0,
  );
}

class PhysioDetail {
  final PhysioCard profile;
  final List<Review> reviews;

  const PhysioDetail({required this.profile, required this.reviews});

  factory PhysioDetail.fromJson(Map<String, dynamic> j) => PhysioDetail(
    profile: PhysioCard.fromJson(j['profile'] as Map<String, dynamic>),
    reviews: (j['reviews'] as List? ?? []).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class Review {
  final String patientName;
  final double rating;
  final String? reviewText;
  final String createdAt;

  const Review({required this.patientName, required this.rating, this.reviewText, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    patientName: j['patient_name'] as String? ?? 'Patient',
    rating: (j['overall_rating'] as num?)?.toDouble() ?? 0.0,
    reviewText: j['review_text'] as String?,
    createdAt: j['created_at'] as String? ?? '',
  );
}
