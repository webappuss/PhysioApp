class DashboardData {
  final List<Booking> upcomingBookings;
  final RehabPlan? activeRehabPlan;
  final bool checkinDoneToday;
  final List<Exercise> exercisesToday;
  final int streakDays;
  final int level;
  final int totalXp;

  const DashboardData({
    required this.upcomingBookings,
    this.activeRehabPlan,
    required this.checkinDoneToday,
    required this.exercisesToday,
    required this.streakDays,
    required this.level,
    required this.totalXp,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    upcomingBookings: (json['upcoming_bookings'] as List? ?? [])
        .map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList(),
    activeRehabPlan: json['active_rehab_plan'] != null
        ? RehabPlan.fromJson(json['active_rehab_plan'] as Map<String, dynamic>) : null,
    checkinDoneToday: json['checkin_done_today'] as bool? ?? false,
    exercisesToday: (json['exercises_today'] as List? ?? [])
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList(),
    streakDays: json['streak_days'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    totalXp: json['total_xp'] as int? ?? 0,
  );
}

class Booking {
  final int id;
  final String uuid;
  final String status;
  final String scheduledDate;
  final String scheduledTime;
  final String bookingType;
  final double totalAmount;

  const Booking({
    required this.id, required this.uuid, required this.status,
    required this.scheduledDate, required this.scheduledTime,
    required this.bookingType, required this.totalAmount,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] as int,
    uuid: j['uuid'] as String,
    status: j['status'] as String,
    scheduledDate: j['scheduled_date'] as String,
    scheduledTime: j['scheduled_time'] as String,
    bookingType: j['booking_type'] as String,
    totalAmount: (j['total_amount'] as num).toDouble(),
  );
}

class RehabPlan {
  final int id;
  final String? title;
  final String? condition;
  final int currentPhase;
  final int totalPhases;
  final String status;

  const RehabPlan({required this.id, this.title, this.condition,
    required this.currentPhase, required this.totalPhases, required this.status});

  factory RehabPlan.fromJson(Map<String, dynamic> j) => RehabPlan(
    id: j['id'] as int,
    title: j['title'] as String?,
    condition: j['condition'] as String?,
    currentPhase: j['current_phase'] as int? ?? 1,
    totalPhases: j['total_phases'] as int? ?? 4,
    status: j['status'] as String? ?? 'active',
  );
}

class Exercise {
  final int id;
  final String name;
  final String? category;
  final String? thumbnailUrl;

  const Exercise({required this.id, required this.name, this.category, this.thumbnailUrl});

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as int,
    name: j['name'] as String,
    category: j['category'] as String?,
    thumbnailUrl: j['thumbnail_url'] as String?,
  );
}
