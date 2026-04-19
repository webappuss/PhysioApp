<?php

namespace App\Modules\Physiotherapist\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Physiotherapist\Services\PhysioService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PhysioController extends Controller
{
    public function __construct(private PhysioService $physioService) {}

    public function profile(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->physioService->getProfile($request->user()),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'                 => 'sometimes|string|max:255',
            'registration_number'  => 'sometimes|string|max:100',
            'registration_body'    => 'sometimes|string|max:100',
            'qualification'        => 'sometimes|string|max:255',
            'specializations'      => 'sometimes|array',
            'specializations.*'    => 'string',
            'years_experience'     => 'sometimes|integer|min:0|max:60',
            'bio'                  => 'sometimes|string|max:1000',
            'languages_spoken'     => 'sometimes|array',
            'service_radius_km'    => 'sometimes|numeric|min:1|max:100',
            'home_visit_charge'    => 'sometimes|numeric|min:0',
            'video_consult_charge' => 'sometimes|numeric|min:0',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated.',
            'data'    => $this->physioService->upsertProfile($request->user(), $validated),
        ]);
    }

    public function availability(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->physioService->getAvailability($request->user()),
        ]);
    }

    public function updateAvailability(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'slots'               => 'required|array|min:1',
            'slots.*.day_of_week' => 'required|integer|min:0|max:6',
            'slots.*.start_time'  => 'required|date_format:H:i',
            'slots.*.end_time'    => 'required|date_format:H:i|after:slots.*.start_time',
            'slots.*.is_active'   => 'sometimes|boolean',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Availability updated.',
            'data'    => $this->physioService->updateAvailability($request->user(), $validated['slots']),
        ]);
    }

    public function dashboard(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->physioService->getDashboard($request->user()),
        ]);
    }

    public function patients(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->physioService->getPatients($request->user()),
        ]);
    }

    public function patientDetail(Request $request, int $patientId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->physioService->getPatientDetail($request->user(), $patientId),
        ]);
    }

    public function earnings(Request $request): JsonResponse
    {
        $period = $request->query('period', 'month');

        return response()->json([
            'success' => true,
            'data'    => $this->physioService->getEarnings($request->user(), $period),
        ]);
    }

    public function updateLocation(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $this->physioService->updateLocation($request->user(), $validated['latitude'], $validated['longitude']);

        return response()->json(['success' => true, 'message' => 'Location updated.']);
    }
}
