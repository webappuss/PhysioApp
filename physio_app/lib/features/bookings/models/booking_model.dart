class BookingDetail {
  final int id;
  final String status;
  final String bookingType;
  final String scheduledDate;
  final String scheduledTime;
  final double totalAmount;
  final String? patientName;
  final String? patientPhone;
  final String? address;
  final String? notes;
  final String paymentStatus;
  final int? sessionId;

  const BookingDetail({
    required this.id,
    required this.status,
    required this.bookingType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.totalAmount,
    this.patientName,
    this.patientPhone,
    this.address,
    this.notes,
    required this.paymentStatus,
    this.sessionId,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> j) => BookingDetail(
    id:            j['id'] as int,
    status:        j['status'] as String,
    bookingType:   j['booking_type'] as String,
    scheduledDate: j['scheduled_date'] as String,
    scheduledTime: j['scheduled_time'] as String,
    totalAmount:   (j['total_amount'] as num).toDouble(),
    patientName:   j['patient_name'] as String?,
    patientPhone:  j['patient_phone'] as String?,
    address:       j['address'] as String?,
    notes:         j['notes'] as String?,
    paymentStatus: j['payment_status'] as String? ?? 'pending',
    sessionId:     j['session_id'] as int?,
  );
}
