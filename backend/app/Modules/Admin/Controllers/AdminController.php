<?php

namespace App\Modules\Admin\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Admin\Services\AdminService;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    public function __construct(
        private AdminService $adminService,
        private AuthService  $authService,
    ) {}

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])
            ->whereIn('role', ['admin', 'super_admin'])
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password ?? '')) {
            return response()->json(['success' => false, 'message' => 'Invalid credentials.'], 401);
        }

        if ($user->status !== 'active') {
            return response()->json(['success' => false, 'message' => 'Account is not active.'], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data'    => $this->authService->issueToken($user),
        ]);
    }

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
            'action' => 'required|in:approve,reject',
            'reason' => 'sometimes|string|max:500',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Physio verification updated.',
            'data'    => $this->adminService->verifyPhysio(
                $request->user(),
                $physioId,
                $validated['action'],
                $validated['reason'] ?? null,
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
            ->leftJoin('patient_profiles', 'payments.patient_id', '=', 'patient_profiles.id')
            ->leftJoin('users as pu', 'patient_profiles.user_id', '=', 'pu.id')
            ->leftJoin('bookings', 'payments.booking_id', '=', 'bookings.id')
            ->leftJoin('physiotherapist_profiles', 'bookings.physio_id', '=', 'physiotherapist_profiles.id')
            ->leftJoin('users as phu', 'physiotherapist_profiles.user_id', '=', 'phu.id')
            ->select(
                'payments.*',
                'pu.name as patient_name',
                'pu.phone as patient_phone',
                'phu.name as physio_name',
            )
            ->when($request->query('status'), fn ($q, $s) => $q->where('payments.status', $s))
            ->orderByDesc('payments.created_at')
            ->paginate(50);

        return response()->json([
            'success' => true,
            'data'    => $payments,
        ]);
    }
}
