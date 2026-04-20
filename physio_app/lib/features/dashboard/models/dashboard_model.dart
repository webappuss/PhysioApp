class PhysioDashboard {
  final int todayBookings;
  final int pendingBookings;
  final int totalPatients;
  final double monthEarnings;
  final double totalEarnings;
  final List<UpcomingBooking> upcomingBookings;
  final double rating;
  final int totalReviews;

  const PhysioDashboard({
    required this.todayBookings,
    required this.pendingBookings,
    required this.totalPatients,
    required this.monthEarnings,
    required this.totalEarnings,
    required this.upcomingBookings,
    required this.rating,
    required this.totalReviews,
  });

  factory PhysioDashboard.fromJson(Map<String, dynamic> j) => PhysioDashboard(
    todayBookings:    (j['today_bookings'] as num?)?.toInt() ?? 0,
    pendingBookings:  (j['pending_bookings'] as num?)?.toInt() ?? 0,
    totalPatients:    (j['total_patients'] as num?)?.toInt() ?? 0,
    monthEarnings:    (j['month_earnings'] as num?)?.toDouble() ?? 0,
    totalEarnings:    (j['total_earnings'] as num?)?.toDouble() ?? 0,
    upcomingBookings: (j['upcoming_bookings'] as List? ?? [])
        .map((e) => UpcomingBooking.fromJson(e as Map<String, dynamic>))
        .toList(),
    rating:           (j['rating'] as num?)?.toDouble() ?? 0,
    totalReviews:     (j['total_reviews'] as num?)?.toInt() ?? 0,
  );
}

class UpcomingBooking {
  final int id;
  final String patientName;
  final String scheduledDate;
  final String scheduledTime;
  final String bookingType;
  final String status;
  final double amount;

  const UpcomingBooking({
    required this.id,
    required this.patientName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.bookingType,
    required this.status,
    required this.amount,
  });

  factory UpcomingBooking.fromJson(Map<String, dynamic> j) => UpcomingBooking(
    id:            j['id'] as int,
    patientName:   j['patient_name'] as String? ?? 'Patient',
    scheduledDate: j['scheduled_date'] as String,
    scheduledTime: j['scheduled_time'] as String,
    bookingType:   j['booking_type'] as String? ?? 'home_visit',
    status:        j['status'] as String,
    amount:        (j['total_amount'] as num?)?.toDouble() ?? 0,
  );
}
