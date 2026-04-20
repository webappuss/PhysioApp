class Exercise {
  final int id;
  final String title;
  final String category;
  final String bodyPart;
  final String difficulty;
  final int durationSec;
  final int sets;
  final int reps;
  final int restSec;
  final List<String> instructions;
  final List<String> equipment;

  const Exercise({
    required this.id,
    required this.title,
    required this.category,
    required this.bodyPart,
    required this.difficulty,
    required this.durationSec,
    required this.sets,
    required this.reps,
    required this.restSec,
    required this.instructions,
    required this.equipment,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id:           json['id'] as int,
        title:        json['title'] as String,
        category:     json['category'] as String,
        bodyPart:     json['body_part'] as String,
        difficulty:   json['difficulty'] as String,
        durationSec:  json['duration_sec'] as int,
        sets:         json['sets'] as int,
        reps:         json['reps'] as int,
        restSec:      json['rest_sec'] as int,
        instructions: List<String>.from(json['instructions'] as List),
        equipment:    List<String>.from(json['equipment'] as List),
      );
}

class RehabPlanExercise {
  final int id;
  final Exercise exercise;
  final int phase;
  final int weekNumber;
  final int orderIndex;
  final bool isCompleted;
  final DateTime? completedAt;

  const RehabPlanExercise({
    required this.id,
    required this.exercise,
    required this.phase,
    required this.weekNumber,
    required this.orderIndex,
    required this.isCompleted,
    this.completedAt,
  });

  factory RehabPlanExercise.fromJson(Map<String, dynamic> json) => RehabPlanExercise(
        id:          json['id'] as int,
        exercise:    Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
        phase:       json['phase'] as int,
        weekNumber:  json['week_number'] as int,
        orderIndex:  json['order_index'] as int,
        isCompleted: json['is_completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}

class RehabPlan {
  final int id;
  final String title;
  final String? diagnosis;
  final int currentPhase;
  final int totalPhases;
  final String status;
  final List<RehabPlanExercise> exercises;

  const RehabPlan({
    required this.id,
    required this.title,
    this.diagnosis,
    required this.currentPhase,
    required this.totalPhases,
    required this.status,
    required this.exercises,
  });

  factory RehabPlan.fromJson(Map<String, dynamic> json) => RehabPlan(
        id:           json['id'] as int,
        title:        json['title'] as String,
        diagnosis:    json['diagnosis'] as String?,
        currentPhase: json['current_phase'] as int,
        totalPhases:  json['total_phases'] as int,
        status:       json['status'] as String,
        exercises:    (json['exercises'] as List? ?? [])
            .map((e) => RehabPlanExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  List<RehabPlanExercise> get currentExercises =>
      exercises.where((e) => e.phase == currentPhase).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  int get completedToday {
    final today = DateTime.now();
    return exercises.where((e) {
      if (!e.isCompleted || e.completedAt == null) return false;
      final d = e.completedAt!;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
  }
}
