class AvailabilitySlot {
  final String dayOfWeek;
  final bool isAvailable;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;

  const AvailabilitySlot({
    required this.dayOfWeek,
    required this.isAvailable,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> j) => AvailabilitySlot(
    dayOfWeek:            j['day_of_week'] as String,
    isAvailable:          (j['is_available'] as bool?) ?? false,
    startTime:            j['start_time'] as String? ?? '09:00',
    endTime:              j['end_time'] as String? ?? '18:00',
    slotDurationMinutes:  (j['slot_duration_minutes'] as num?)?.toInt() ?? 60,
  );

  Map<String, dynamic> toJson() => {
    'day_of_week':            dayOfWeek,
    'is_available':           isAvailable,
    'start_time':             startTime,
    'end_time':               endTime,
    'slot_duration_minutes':  slotDurationMinutes,
  };

  AvailabilitySlot copyWith({
    bool? isAvailable,
    String? startTime,
    String? endTime,
    int? slotDurationMinutes,
  }) => AvailabilitySlot(
    dayOfWeek:           dayOfWeek,
    isAvailable:         isAvailable ?? this.isAvailable,
    startTime:           startTime ?? this.startTime,
    endTime:             endTime ?? this.endTime,
    slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
  );
}
