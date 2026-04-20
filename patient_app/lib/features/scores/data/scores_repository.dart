import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/score_model.dart';

final scoresRepositoryProvider = Provider<ScoresRepository>((ref) {
  return ScoresRepository(ref.watch(apiClientProvider));
});

class ScoresRepository {
  final ApiClient _api;
  ScoresRepository(this._api);

  Future<List<OutcomeScore>> getScores() async {
    final res = await _api.get(ApiEndpoints.scores);
    return (res.data['data'] as List? ?? [])
        .map((e) => OutcomeScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OutcomeScore>> getScoreHistory(String scaleCode) async {
    final res = await _api.get('${ApiEndpoints.scores}/$scaleCode/history');
    return (res.data['data'] as List? ?? [])
        .map((e) => OutcomeScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OutcomeScore> recordScore({
    required String scaleCode,
    required int totalScore,
    required String interpretation,
    int? weekNumber,
    String? notes,
  }) async {
    final res = await _api.post(ApiEndpoints.scores, data: {
      'scale_code':     scaleCode,
      'total_score':    totalScore,
      'interpretation': interpretation,
      if (weekNumber != null) 'week_number': weekNumber,
      if (notes != null)      'notes': notes,
    });
    return OutcomeScore.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
