import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/exercise_model.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(apiClientProvider));
});

class ExerciseRepository {
  final ApiClient _api;
  ExerciseRepository(this._api);

  Future<RehabPlan> getRehabPlan(int id) async {
    final response = await _api.get(ApiEndpoints.rehabPlanDetail(id));
    return RehabPlan.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<RehabPlan>> getMyRehabPlans() async {
    final response = await _api.get('${ApiEndpoints.rehabPlans}?my=1');
    final list = response.data['data'] as List;
    return list.map((e) => RehabPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> completeExercise(int rehabExerciseId) async {
    await _api.post(ApiEndpoints.completeExercise(rehabExerciseId), data: {});
  }

  Future<Exercise> aiModifyExercise(int rehabExerciseId, String reason) async {
    final response = await _api.post(
      ApiEndpoints.aiModifyExercise(rehabExerciseId),
      data: {'reason': reason},
    );
    return Exercise.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
