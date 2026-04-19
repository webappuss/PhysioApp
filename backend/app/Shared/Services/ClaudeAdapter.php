<?php

namespace App\Shared\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ClaudeAdapter
{
    private string $apiKey;
    private string $model;
    private int    $maxTokens;

    public function __construct(private AuditLogger $auditLogger)
    {
        $this->apiKey    = config('physioconnect.ai.anthropic_api_key');
        $this->model     = config('physioconnect.ai.model', 'claude-sonnet-4-20250514');
        $this->maxTokens = config('physioconnect.ai.max_tokens', 1200);
    }

    public function triage(array $intakeData): array
    {
        $prompt   = $this->buildTriagePrompt($intakeData);
        $response = $this->call($this->triageSystemPrompt(), $prompt, 1200);
        return $this->parseJsonResponse($response);
    }

    public function generateRehabPlan(array $planData): array
    {
        $response = $this->call($this->rehabPlanSystemPrompt(), $this->buildPlanPrompt($planData), 2500);
        return $this->parseJsonResponse($response);
    }

    public function modifyExercise(array $feedbackData): array
    {
        $system   = 'You are an evidence-based physiotherapy AI. Given patient feedback on an exercise, suggest adjustments to sets, reps, technique, or alternatives. Respond in valid JSON only with keys: modified_sets, modified_reps, modified_technique, alternative_exercise, reasoning.';
        $response = $this->call($system, json_encode($feedbackData), 800);
        return $this->parseJsonResponse($response);
    }

    public function checkinInsight(array $checkinData): array
    {
        $system   = 'You are PhysioConnect\'s patient wellness AI. Analyse daily check-in data and provide a personalised, warm, clinically-aware insight. Respond in JSON: { "insight": "string", "alert_level": "green|amber|red", "action_today": "string" }';
        $response = $this->call($system, json_encode($checkinData), 600);
        return $this->parseJsonResponse($response);
    }

    public function structureSoap(string $rawNotes): array
    {
        $system   = 'You are a clinical documentation AI. Convert free-text physiotherapy session notes into structured SOAP format. Respond in JSON: { "subjective": "...", "objective": "...", "assessment": "...", "plan": "..." }';
        $response = $this->call($system, $rawNotes, 1000);
        return $this->parseJsonResponse($response);
    }

    private function call(string $systemPrompt, string $userMessage, int $maxTokens): string
    {
        if (! $this->apiKey) {
            Log::warning('Claude API key not configured — returning fallback response.');
            return json_encode(['error' => 'AI service unavailable', 'fallback' => true]);
        }

        $cacheKey = 'ai_response:' . md5($systemPrompt . $userMessage);

        if ($cached = Cache::get($cacheKey)) {
            return $cached;
        }

        try {
            $response = Http::withHeaders([
                'x-api-key'         => $this->apiKey,
                'anthropic-version' => '2023-06-01',
                'content-type'      => 'application/json',
            ])->timeout(30)->post('https://api.anthropic.com/v1/messages', [
                'model'      => $this->model,
                'max_tokens' => $maxTokens,
                'system'     => $systemPrompt,
                'messages'   => [['role' => 'user', 'content' => $userMessage]],
            ]);

            if ($response->failed()) {
                Log::error('Claude API error', ['status' => $response->status(), 'body' => $response->body()]);
                return json_encode(['error' => 'AI service error', 'fallback' => true]);
            }

            $text = $response->json('content.0.text', '{}');

            Cache::put($cacheKey, $text, config('physioconnect.ai.cache_ttl', 3600));

            $this->auditLogger->log(null, 'ai_api_call', 'claude_api', null, [], [
                'tokens_used' => $response->json('usage.output_tokens'),
                'model'       => $this->model,
            ]);

            return $text;

        } catch (\Throwable $e) {
            Log::error('Claude API exception', ['message' => $e->getMessage()]);
            return json_encode(['error' => 'AI service unavailable', 'fallback' => true]);
        }
    }

    private function parseJsonResponse(string $rawText): array
    {
        // Strip markdown code fences if present
        $cleaned = preg_replace('/```(?:json)?\n?/', '', $rawText);
        $cleaned = trim($cleaned, '`');

        $decoded = json_decode($cleaned, true);

        return is_array($decoded) ? $decoded : ['raw' => $rawText, 'parse_error' => true];
    }

    private function triageSystemPrompt(): string
    {
        return <<<PROMPT
You are PhysioConnect's clinical triage AI, integrated with India's leading physiotherapy platform. You assist qualified physiotherapists and help route patients appropriately.

ALWAYS respond in valid JSON only. No markdown, no preamble.
ALWAYS be medically conservative — when in doubt, recommend professional evaluation.
NEVER provide specific diagnostic certainty — you are a triage aid, not a diagnostician.

Response schema:
{
  "triageLevel": "Physiotherapy|Orthopaedic Consultation|Neurological Referral|Emergency",
  "urgency": "Routine|Expedite|Urgent|Emergency",
  "confidence": 0-100,
  "primaryDiagnosis": "string",
  "differentials": ["string"],
  "reasoning": "string",
  "preliminaryPlan": ["string"],
  "redFlagPresent": boolean,
  "predictedRecovery": "string",
  "message": "warm patient message in simple language"
}
PROMPT;
    }

    private function rehabPlanSystemPrompt(): string
    {
        return <<<PROMPT
You are an evidence-based physiotherapy AI for PhysioConnect India. You generate structured rehabilitation programs based on clinical guidelines. Your plans are reviewed and modified by qualified physiotherapists before being applied.

Generate practical, safe, phased exercise programs. Use metric units. Reference Indian clinical context where relevant (e.g. floor-sitting, low-chair transfers, squatting activities).

ALWAYS respond in valid JSON only. No markdown.

Response schema:
{
  "title": "string",
  "total_phases": number,
  "estimated_weeks": number,
  "phases": [
    {
      "phase_number": 1,
      "name": "string",
      "focus": "string",
      "start_week": 1,
      "end_week": 2,
      "goals": ["string"],
      "exercises": [
        {
          "name": "string",
          "sets": number,
          "reps": "string",
          "frequency_per_week": number,
          "technique_cue": "string",
          "progression_criteria": "string"
        }
      ],
      "precautions": ["string"]
    }
  ],
  "red_flags_to_watch": ["string"],
  "home_advice": "string"
}
PROMPT;
    }

    private function buildTriagePrompt(array $data): string
    {
        return json_encode([
            'chief_complaint'    => $data['chief_complaint'] ?? '',
            'onset_type'         => $data['onset_type'] ?? '',
            'duration_days'      => $data['duration_days'] ?? 0,
            'vas_score'          => $data['vas_score'] ?? 0,
            'pathology_group'    => $data['pathology_group'] ?? '',
            'red_flags'          => $data['red_flags'] ?? [],
            'pain_sites'         => $data['pain_sites'] ?? [],
            'previous_treatment' => $data['previous_treatment'] ?? '',
            'patient_age'        => $data['patient_age'] ?? null,
        ]);
    }

    private function buildPlanPrompt(array $data): string
    {
        return json_encode([
            'condition'          => $data['condition'] ?? '',
            'pathology_group'    => $data['pathology_group'] ?? '',
            'intake_summary'     => $data['intake_summary'] ?? '',
            'outcome_scores'     => $data['outcome_scores'] ?? [],
            'patient_goals'      => $data['patient_goals'] ?? '',
            'patient_age'        => $data['patient_age'] ?? null,
            'surgery_history'    => $data['surgery_history'] ?? null,
            'comorbidities'      => $data['comorbidities'] ?? [],
        ]);
    }
}
