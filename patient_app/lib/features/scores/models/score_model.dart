class OutcomeScore {
  final int id;
  final String scaleCode;
  final String scaleName;
  final int totalScore;
  final String interpretation;
  final int weekNumber;
  final DateTime sessionDate;
  final String? notes;

  const OutcomeScore({
    required this.id,
    required this.scaleCode,
    required this.scaleName,
    required this.totalScore,
    required this.interpretation,
    required this.weekNumber,
    required this.sessionDate,
    this.notes,
  });

  factory OutcomeScore.fromJson(Map<String, dynamic> j) => OutcomeScore(
        id:             j['id'] as int,
        scaleCode:      j['scale_code'] as String,
        scaleName:      j['scale_name'] as String? ?? j['scale_code'] as String,
        totalScore:     (j['total_score'] as num).toInt(),
        interpretation: j['interpretation'] as String? ?? '',
        weekNumber:     (j['week_number'] as num?)?.toInt() ?? 0,
        sessionDate:    DateTime.parse(j['session_date'] as String),
        notes:          j['notes'] as String?,
      );
}

// Common outcome measure scales with their score ranges
class OutcomeScale {
  final String code;
  final String name;
  final int minScore;
  final int maxScore;
  final String description;
  final List<_ScoreItem> items;

  const OutcomeScale({
    required this.code,
    required this.name,
    required this.minScore,
    required this.maxScore,
    required this.description,
    required this.items,
  });
}

class _ScoreItem {
  final String label;
  final int value;
  const _ScoreItem(this.label, this.value);
}

final kOutcomeScales = [
  OutcomeScale(
    code: 'VAS',
    name: 'Visual Analogue Scale (Pain)',
    minScore: 0,
    maxScore: 10,
    description: 'Rate your pain level from 0 (no pain) to 10 (worst possible pain)',
    items: [],
  ),
  OutcomeScale(
    code: 'KOOS',
    name: 'KOOS Knee Score',
    minScore: 0,
    maxScore: 100,
    description: 'Knee injury and osteoarthritis outcome score (higher = better)',
    items: [],
  ),
  OutcomeScale(
    code: 'DASH',
    name: 'DASH Upper Limb',
    minScore: 0,
    maxScore: 100,
    description: 'Disability of Arm, Shoulder and Hand (lower = better)',
    items: [],
  ),
  OutcomeScale(
    code: 'NDI',
    name: 'Neck Disability Index',
    minScore: 0,
    maxScore: 50,
    description: 'Neck disability index (lower = better)',
    items: [],
  ),
  OutcomeScale(
    code: 'PSFS',
    name: 'Patient-Specific Functional Scale',
    minScore: 0,
    maxScore: 10,
    description: 'Rate ability to perform specific activities (0=unable, 10=same as before)',
    items: [],
  ),
];
