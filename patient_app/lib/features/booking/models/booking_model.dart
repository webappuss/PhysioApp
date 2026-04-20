class BookingDetail {
  final int id;
  final String uuid;
  final String status;
  final String bookingType;
  final String scheduledDate;
  final String scheduledTime;
  final double sessionFee;
  final double platformFee;
  final double totalAmount;
  final String paymentStatus;
  final String? patientName;
  final String? physioName;
  final String? physioPhone;
  final String? physioAvatar;
  final String? physioQualification;
  final double? physioRating;

  const BookingDetail({
    required this.id, required this.uuid, required this.status,
    required this.bookingType, required this.scheduledDate, required this.scheduledTime,
    required this.sessionFee, required this.platformFee, required this.totalAmount,
    required this.paymentStatus, this.patientName, this.physioName, this.physioPhone,
    this.physioAvatar, this.physioQualification, this.physioRating,
  });

  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get isPaid => paymentStatus == 'captured';

  factory BookingDetail.fromJson(Map<String, dynamic> j) => BookingDetail(
    id: j['id'] as int,
    uuid: j['uuid'] as String,
    status: j['status'] as String,
    bookingType: j['booking_type'] as String,
    scheduledDate: j['scheduled_date'] as String,
    scheduledTime: j['scheduled_time'] as String,
    sessionFee: (j['session_fee'] as num).toDouble(),
    platformFee: (j['platform_fee'] as num).toDouble(),
    totalAmount: (j['total_amount'] as num).toDouble(),
    paymentStatus: j['payment_status'] as String,
    patientName: j['patient_name'] as String?,
    physioName: j['physio_name'] as String?,
    physioPhone: j['physio_phone'] as String?,
    physioAvatar: j['physio_avatar'] as String?,
    physioQualification: j['physio_qualification'] as String?,
    physioRating: (j['physio_rating'] as num?)?.toDouble(),
  );
}
