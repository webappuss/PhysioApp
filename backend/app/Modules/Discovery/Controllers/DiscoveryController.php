<?php

namespace App\Modules\Discovery\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Discovery\Services\DiscoveryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiscoveryController extends Controller
{
    public function __construct(private DiscoveryService $discoveryService) {}

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'latitude'     => 'sometimes|numeric|between:-90,90',
            'longitude'    => 'sometimes|numeric|between:-180,180',
            'radius_km'    => 'sometimes|numeric|min:1|max:100',
            'specialty'    => 'sometimes|string',
            'booking_type' => 'sometimes|in:home_visit,video_consult,clinic',
            'min_rating'   => 'sometimes|numeric|min:0|max:5',
            'per_page'     => 'sometimes|integer|min:5|max:50',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->discoveryService->searchPhysios($validated),
        ]);
    }

    public function show(int $physioId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->discoveryService->getPhysioDetail($physioId),
        ]);
    }

    public function availability(Request $request, int $physioId): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date|after_or_equal:today',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->discoveryService->getAvailableSlots($physioId, $validated['date']),
        ]);
    }
}
