class ApiEndpoints {
  static const sendOtp       = '/auth/send-otp';
  static const verifyOtp     = '/auth/verify-otp';
  static const logout        = '/auth/logout';
  static const me            = '/auth/me';

  static const physioProfile     = '/physio/profile';
  static const physioAvailability= '/physio/availability';
  static const physioDashboard   = '/physio/dashboard';
  static const physioPatients    = '/physio/patients';
  static const physioEarnings    = '/physio/earnings';
  static const physioLocation    = '/physio/location';

  static String patientDetail(int id) => '/physio/patients/$id';

  static const bookings = '/bookings';
  static String bookingDetail(int id)  => '/bookings/$id';
  static String confirmBooking(int id) => '/bookings/$id/confirm';
  static String startBooking(int id)   => '/bookings/$id/start';
  static String completeBooking(int id)=> '/bookings/$id/complete';
  static String cancelBooking(int id)  => '/bookings/$id/cancel';

  static const sessions = '/sessions';
  static String sessionDetail(int id)  => '/sessions/$id';
  static String soapNotes(int id)      => '/sessions/$id/soap';
}
