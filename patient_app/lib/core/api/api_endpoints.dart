class ApiEndpoints {
  // Auth
  static const sendOtp    = '/auth/send-otp';
  static const verifyOtp  = '/auth/verify-otp';
  static const logout     = '/auth/logout';
  static const me         = '/auth/me';

  // Patient
  static const profile        = '/patient/profile';
  static const dashboard      = '/patient/dashboard';
  static const careTeam       = '/patient/care-team';
  static const checkins       = '/patient/checkins';
  static const scores         = '/patient/scores';

  // Discovery
  static const discoverPhysios = '/discover/physios';
  static String physioDetail(int id) => '/discover/physios/$id';
  static String physioAvailability(int id) => '/discover/physios/$id/availability';

  // Bookings
  static const bookings = '/bookings';
  static String bookingDetail(int id) => '/bookings/$id';
  static String confirmBooking(int id) => '/bookings/$id/confirm';
  static String cancelBooking(int id) => '/bookings/$id/cancel';
  static String bookingTracking(int id) => '/bookings/$id/tracking';

  // Payments
  static const createOrder    = '/payments/create-order';
  static const verifyPayment  = '/payments/verify';
  static const paymentHistory = '/payments/history';

  // Exercises
  static const exercises = '/exercises';
  static String completeExercise(int id) => '/exercises/$id/complete';
  static String aiModifyExercise(int id) => '/exercises/$id/ai-modify';

  // Rehab
  static const rehabPlans = '/rehab-plans';
  static String rehabPlanDetail(int id) => '/rehab-plans/$id';
}
