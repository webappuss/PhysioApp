import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scores_repository.dart';
import '../models/score_model.dart';

final scoresProvider = FutureProvider.autoDispose<List<OutcomeScore>>((ref) {
  return ref.watch(scoresRepositoryProvider).getScores();
});

final scoreHistoryProvider =
    FutureProvider.autoDispose.family<List<OutcomeScore>, String>((ref, code) {
  return ref.watch(scoresRepositoryProvider).getScoreHistory(code);
});

class RecordScoreNotifier extends AutoDisposeAsyncNotifier<OutcomeScore?> {
  @override
  Future<OutcomeScore?> build() async => null;

  Future<void> record({
    required String scaleCode,
    required int totalScore,
    required String interpretation,
    int? weekNumber,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final score = await ref.read(scoresRepositoryProvider).recordScore(
            scaleCode:     scaleCode,
            totalScore:    totalScore,
            interpretation: interpretation,
            weekNumber:    weekNumber,
            notes:         notes,
          );
      ref.invalidate(scoresProvider);
      return score;
    });
  }
}

final recordScoreProvider =
    AsyncNotifierProvider.autoDispose<RecordScoreNotifier, OutcomeScore?>(
  RecordScoreNotifier.new,
);
