<?php

namespace App\Modules\Patient\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Patient\Services\PatientService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PatientController extends Controller
{
    public function __construct(private PatientService $patientService) {}

    public function profile(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->patientService->getProfile($request->user()),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'                    => 'sometimes|string|max:255',
            'date_of_birth'           => 'sometimes|date|before:today',
            'gender'                  => 'sometimes|in:male,female,other',
            'blood_group'             => 'sometimes|string|max:5',
            'height_cm'               => 'sometimes|numeric|min:50|max:250',
            'weight_kg'               => 'sometimes|numeric|min:10|max:300',
            'occupation'              => 'sometimes|string|max:255',
            'medical_history'         => 'sometimes|string',
            'current_medications'     => 'sometimes|string',
            'allergies'               => 'sometimes|string',
            'emergency_contact_name'  => 'sometimes|string|max:255',
            'emergency_contact_phone' => 'sometimes|string|regex:/^[6-9]\d{9}$/',
            'preferred_language'      => 'sometimes|in:en,hi,gu',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'data'    => $this->patientService->upsertProfile($request->user(), $validated),
        ]);
    }

    public function dashboard(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->patientService->getDashboard($request->user()),
        ]);
    }

    public function careTeam(Request $request): JsonResponse
    {
        $patientProfile = \DB::table('patient_profiles')
            ->where('user_id', $request->user()->id)->first();

        $team = \DB::table('care_teams')
            ->where('patient_id', $patientProfile?->id)
            ->where('is_active', true)
            ->first();

        return response()->json([
            'success' => true,
            'data'    => $team,
        ]);
    }

    public function checkins(Request $request): JsonResponse
    {
        $days = (int) $request->query('days', 30);

        return response()->json([
            'success' => true,
            'data'    => $this->patientService->getCheckins($request->user(), min($days, 90)),
        ]);
    }

    public function storeCheckin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'checkin_date'  => 'sometimes|date|before_or_equal:today',
            'pain_score'    => 'sometimes|numeric|min:0|max:10',
            'mood_score'    => 'sometimes|integer|min:0|max:10',
            'sleep_hours'   => 'sometimes|numeric|min:0|max:24',
            'energy_level'  => 'sometimes|integer|min:0|max:10',
            'patient_notes' => 'sometimes|string|max:1000',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Check-in recorded.',
            'data'    => $this->patientService->createCheckin($request->user(), $validated),
        ], 201);
    }

    public function scores(Request $request): JsonResponse
    {
        $code = $request->query('code');

        return response()->json([
            'success' => true,
            'data'    => $this->patientService->getOutcomeScores($request->user(), $code),
        ]);
    }

    public function storeScore(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'score_code'   => 'required|string|exists:outcome_score_definitions,code',
            'raw_score'    => 'required|numeric',
            'intake_id'    => 'sometimes|integer',
            'session_date' => 'sometimes|date',
            'week_number'  => 'sometimes|integer|min:1|max:52',
            'notes'        => 'sometimes|string|max:500',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Score recorded.',
            'data'    => $this->patientService->recordOutcomeScore($request->user(), $validated),
        ], 201);
    }

    public function scoreHistory(Request $request, string $code): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->patientService->getOutcomeScores($request->user(), $code),
        ]);
    }
}
