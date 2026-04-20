class SoapNotes {
  final int? sessionId;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? homeworkInstructions;

  const SoapNotes({
    this.sessionId,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.homeworkInstructions,
  });

  factory SoapNotes.fromJson(Map<String, dynamic> j) => SoapNotes(
    sessionId:            j['id'] as int?,
    subjective:           j['soap_subjective'] as String?,
    objective:            j['soap_objective'] as String?,
    assessment:           j['soap_assessment'] as String?,
    plan:                 j['soap_plan'] as String?,
    homeworkInstructions: j['homework_instructions'] as String?,
  );
}
