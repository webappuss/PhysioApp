<?php

namespace App\Modules\Admin\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Admin\Services\AdminService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function __construct(private AdminService $adminService) {}

    public function dashboard(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->adminService->getDashboard(),
        ]);
    }

    public function pendingPhysios(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data'    => $this->adminService->pendingPhysios((int) $request->query('page', 1)),
        ]);
    }

    public function verifyPhysio(Request $request, int $physioId): JsonResponse
    {
        $validated = $request->validate([
            'decision' => 'required|in:approve,reject',
            'notes'    => 'sometimes|string|max:500',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Physio verification updated.',
            'data'    => $this->adminService->verifyPhysio(
                $request->user(),
                $physioId,
                $validated['decision'],
                $validated['notes'] ?? null,
            ),
        ]);
    }

    public function bookings(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'status' => 'sometimes|string',
            'date'   => 'sometimes|date',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->adminService->getBookings($filters),
        ]);
    }

    public function revenue(Request $request): JsonResponse
    {
        $period = $request->query('period', 'month');

        return response()->json([
            'success' => true,
            'data'    => $this->adminService->getRevenue($period),
        ]);
    }

    public function users(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'role'   => 'sometimes|in:patient,physiotherapist,surgeon,psychologist,admin',
            'status' => 'sometimes|in:pending,active,suspended,deleted',
            'search' => 'sometimes|string|max:100',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $this->adminService->getUsers($filters),
        ]);
    }

    public function updateUserStatus(Request $request, int $userId): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:active,suspended,deleted',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User status updated.',
            'data'    => $this->adminService->updateUserStatus($request->user(), $userId, $validated['status']),
        ]);
    }

    public function payments(Request $request): JsonResponse
    {
        $payments = \DB::table('payments')
            ->join('patient_profiles', 'payments.patient_id', '=', 'patient_profiles.id')
            ->join('users', 'patient_profiles.user_id', '=', 'users.id')
            ->select('payments.*', 'users.name as patient_name', 'users.phone as patient_phone')
            ->orderByDesc('payments.created_at')
            ->paginate(25);

        return response()->json([
            'success' => true,
            'data'    => $payments,
        ]);
    }
}
