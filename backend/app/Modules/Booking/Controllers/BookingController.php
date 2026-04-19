<?php

namespace App\Modules\Booking\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Booking\Services\BookingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function __construct(private BookingService $bookingService) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'physio_id'      => 'required|integer|exists:physiotherapist_profiles,id',
            'booking_type'   => 'required|in:home_visit,video_consult,clinic',
            'scheduled_date' => 'required|date|after_or_equal:today',
            'scheduled_time' => 'required|date_format:H:i',
            'address_id'     => 'sometimes|integer|exists:patient_addresses,id',
            'package_id'     => 'sometimes|integer|exists:session_packages,id',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking created. Awaiting physio confirmation.',
            'data'    => $this->bookingService->create($request->user(), $validated),
        ], 201);
    }

    public function show(Request $request, int $bookingId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->bookingService->get($bookingId, $request->user()),
        ]);
    }

    public function confirm(Request $request, int $bookingId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Booking confirmed.',
            'data'    => $this->bookingService->transition($bookingId, $request->user(), 'confirm'),
        ]);
    }

    public function start(Request $request, int $bookingId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Status updated: en route.',
            'data'    => $this->bookingService->transition($bookingId, $request->user(), 'start'),
        ]);
    }

    public function complete(Request $request, int $bookingId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Session completed.',
            'data'    => $this->bookingService->transition($bookingId, $request->user(), 'complete'),
        ]);
    }

    public function cancel(Request $request, int $bookingId): JsonResponse
    {
        $validated = $request->validate([
            'reason' => 'sometimes|string|max:500',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking cancelled.',
            'data'    => $this->bookingService->transition($bookingId, $request->user(), 'cancel', $validated),
        ]);
    }

    public function tracking(int $bookingId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->bookingService->getTracking($bookingId),
        ]);
    }
}

class SessionController extends Controller
{
    public function __construct(private BookingService $bookingService) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'booking_id'     => 'required|integer|exists:bookings,id',
            'session_number' => 'sometimes|integer|min:1',
            'pain_at_start'  => 'sometimes|numeric|min:0|max:10',
            'pain_at_end'    => 'sometimes|numeric|min:0|max:10',
            'techniques_used'=> 'sometimes|array',
            'duration_mins'  => 'sometimes|integer|min:1|max:180',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->bookingService->createSession($request->user(), $validated),
        ], 201);
    }

    public function show(Request $request, int $sessionId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->bookingService->getSession($sessionId, $request->user()),
        ]);
    }

    public function updateSoap(Request $request, int $sessionId): JsonResponse
    {
        $validated = $request->validate([
            'subjective'      => 'sometimes|string',
            'objective'       => 'sometimes|string',
            'assessment'      => 'sometimes|string',
            'plan'            => 'sometimes|string',
            'pain_at_start'   => 'sometimes|numeric|min:0|max:10',
            'pain_at_end'     => 'sometimes|numeric|min:0|max:10',
            'techniques_used' => 'sometimes|array',
            'duration_mins'   => 'sometimes|integer|min:1|max:180',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Session notes saved.',
            'data'    => $this->bookingService->updateSoap($request->user(), $sessionId, $validated),
        ]);
    }
}
