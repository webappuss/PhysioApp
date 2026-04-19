<?php

namespace App\Modules\Admin\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use App\Shared\Services\NotificationService;
use Illuminate\Support\Facades\DB;

class AdminService
{
    public function __construct(
        private AuditLogger         $auditLogger,
        private NotificationService $notificationService,
    ) {}

    public function getDashboard(): array
    {
        return [
            'users' => [
                'total'    => DB::table('users')->whereNotNull('deleted_at')->count() === 0
                    ? DB::table('users')->count()
                    : DB::table('users')->whereNull('deleted_at')->count(),
                'patients' => DB::table('users')->where('role', 'patient')->where('status', 'active')->count(),
                'physios'  => DB::table('users')->where('role', 'physiotherapist')->where('status', 'active')->count(),
            ],
            'physios_pending_verification' => DB::table('physiotherapist_profiles')->where('is_verified', false)->count(),
            'bookings' => [
                'today'     => DB::table('bookings')->where('scheduled_date', today())->count(),
                'this_month'=> DB::table('bookings')->whereMonth('created_at', now()->month)->count(),
                'completed' => DB::table('bookings')->where('status', 'completed')->count(),
            ],
            'revenue' => [
                'today'     => DB::table('bookings')
                    ->where('status', 'completed')
                    ->whereDate('completed_at', today())
                    ->sum('platform_fee'),
                'this_month'=> DB::table('bookings')
                    ->where('status', 'completed')
                    ->whereMonth('completed_at', now()->month)
                    ->sum('platform_fee'),
            ],
        ];
    }

    public function pendingPhysios(int $page = 1): array
    {
        return DB::table('physiotherapist_profiles')
            ->join('users', 'physiotherapist_profiles.user_id', '=', 'users.id')
            ->where('physiotherapist_profiles.is_verified', false)
            ->where('users.status', '!=', 'deleted')
            ->select(
                'physiotherapist_profiles.*',
                'users.name',
                'users.phone',
                'users.email',
                'users.created_at as registered_at',
            )
            ->orderBy('physiotherapist_profiles.created_at')
            ->paginate(20, ['*'], 'page', $page)
            ->toArray();
    }

    public function verifyPhysio(User $admin, int $physioId, string $decision, ?string $notes = null): array
    {
        $profile = DB::table('physiotherapist_profiles')->find($physioId);
        abort_if(! $profile, 404, 'Physiotherapist not found.');

        if ($decision === 'approve') {
            DB::table('physiotherapist_profiles')->where('id', $physioId)->update([
                'is_verified' => true,
                'verified_at' => now(),
                'verified_by' => $admin->id,
                'updated_at'  => now(),
            ]);
            DB::table('users')->where('id', $profile->user_id)->update(['status' => 'active']);

            $this->notificationService->sendPush(
                $profile->user_id,
                'Verification Approved',
                'Congratulations! Your PhysioConnect profile has been verified. You can now start accepting bookings.',
                ['type' => 'verification_approved']
            );

            $this->auditLogger->log($admin, 'approve_physio', 'physiotherapist_profiles', $physioId);
        } else {
            DB::table('users')->where('id', $profile->user_id)->update(['status' => 'suspended']);

            $this->notificationService->sendPush(
                $profile->user_id,
                'Verification Update',
                'Your verification could not be completed. Please contact support for assistance.',
                ['type' => 'verification_rejected']
            );

            $this->auditLogger->log($admin, 'reject_physio', 'physiotherapist_profiles', $physioId, [], ['notes' => $notes]);
        }

        return (array) DB::table('physiotherapist_profiles')->find($physioId);
    }

    public function getBookings(array $filters = []): array
    {
        $query = DB::table('bookings')
            ->join('patient_profiles', 'bookings.patient_id', '=', 'patient_profiles.id')
            ->join('users as pu', 'patient_profiles.user_id', '=', 'pu.id')
            ->join('physiotherapist_profiles', 'bookings.physio_id', '=', 'physiotherapist_profiles.id')
            ->join('users as phu', 'physiotherapist_profiles.user_id', '=', 'phu.id')
            ->select(
                'bookings.*',
                'pu.name as patient_name',
                'phu.name as physio_name',
            );

        if ($status = $filters['status'] ?? null) {
            $query->where('bookings.status', $status);
        }
        if ($date = $filters['date'] ?? null) {
            $query->where('bookings.scheduled_date', $date);
        }

        return $query->orderByDesc('bookings.created_at')->paginate(25)->toArray();
    }

    public function getRevenue(string $period = 'month'): array
    {
        $query = DB::table('bookings')
            ->where('status', 'completed')
            ->where('payment_status', 'captured');

        if ($period === 'month') {
            $query->whereMonth('completed_at', now()->month)->whereYear('completed_at', now()->year);
        } elseif ($period === 'year') {
            $query->whereYear('completed_at', now()->year);
        }

        $bookings = $query->get();

        $dailyRevenue = $bookings->groupBy(fn($b) => substr($b->completed_at, 0, 10))
            ->map(fn($group) => [
                'date'            => $group->first()->completed_at ? substr($group->first()->completed_at, 0, 10) : null,
                'platform_revenue'=> $group->sum('platform_fee'),
                'gross_revenue'   => $group->sum('total_amount'),
                'sessions'        => $group->count(),
            ])->values();

        return [
            'period'           => $period,
            'total_gross'      => $bookings->sum('total_amount'),
            'platform_revenue' => $bookings->sum('platform_fee'),
            'physio_payouts'   => $bookings->sum('session_fee'),
            'sessions'         => $bookings->count(),
            'daily_breakdown'  => $dailyRevenue,
        ];
    }

    public function getUsers(array $filters = []): array
    {
        $query = DB::table('users')->whereNull('deleted_at');

        if ($role = $filters['role'] ?? null) {
            $query->where('role', $role);
        }
        if ($status = $filters['status'] ?? null) {
            $query->where('status', $status);
        }
        if ($search = $filters['search'] ?? null) {
            $query->where(fn($q) => $q->where('name', 'like', "%{$search}%")->orWhere('phone', 'like', "%{$search}%"));
        }

        return $query->orderByDesc('created_at')->paginate(25)->toArray();
    }

    public function updateUserStatus(User $admin, int $userId, string $status): array
    {
        $user = DB::table('users')->find($userId);
        abort_if(! $user, 404);
        abort_if($user->role === 'super_admin', 403, 'Cannot modify super admin status.');

        DB::table('users')->where('id', $userId)->update(['status' => $status, 'updated_at' => now()]);
        $this->auditLogger->log($admin, "user_status_{$status}", 'users', $userId);

        return (array) DB::table('users')->find($userId);
    }
}
