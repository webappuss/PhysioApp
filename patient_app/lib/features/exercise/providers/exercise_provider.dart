import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exercise_repository.dart';
import '../models/exercise_model.dart';

final myRehabPlansProvider = FutureProvider.autoDispose<List<RehabPlan>>((ref) {
  return ref.watch(exerciseRepositoryProvider).getMyRehabPlans();
});

final rehabPlanProvider = FutureProvider.autoDispose.family<RehabPlan, int>((ref, id) {
  return ref.watch(exerciseRepositoryProvider).getRehabPlan(id);
});

class ExerciseCompleteNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> complete(int rehabExerciseId, int planId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(exerciseRepositoryProvider).completeExercise(rehabExerciseId);
      ref.invalidate(rehabPlanProvider(planId));
    });
  }
}

final exerciseCompleteProvider =
    AsyncNotifierProvider.autoDispose<ExerciseCompleteNotifier, void>(
  ExerciseCompleteNotifier.new,
);
