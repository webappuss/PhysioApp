<?php

namespace App\Modules\Physiotherapist\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class PhysioService
{
    public function __construct(private AuditLogger $auditLogger) {}

    public function getProfile(User $user): array
    {
        $profile = DB::table('physiotherapist_profiles')
            ->where('user_id', $user->id)
            ->first();

        if (! $profile) return [];

        $docs = DB::table('physiotherapist_documents')
            ->where('physio_id', $profile->id)
            ->get();

        $availability = DB::table('physiotherapist_availability')
            ->where('physio_id', $profile->id)
            ->where('is_active', true)
            ->get();

        $data             = (array) $profile;
        $data['user']     = ['name' => $user->name, 'email' => $user->email, 'phone' => $user->phone];
        $data['documents']    = $docs;
        $data['availability'] = $availability;

        return $data;
    }

    public function upsertProfile(User $user, array $data): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->first();

        $payload = array_filter([
            'registration_number' => $data['registration_number'] ?? null,
            'registration_body'   => $data['registration_body'] ?? null,
            'qualification'       => $data['qualification'] ?? null,
            'specializations'     => isset($data['specializations']) ? json_encode($data['specializations']) : null,
            'years_experience'    => $data['years_experience'] ?? null,
            'bio'                 => $data['bio'] ?? null,
            'languages_spoken'    => isset($data['languages_spoken']) ? json_encode($data['languages_spoken']) : null,
            'service_radius_km'   => $data['service_radius_km'] ?? null,
            'home_visit_charge'   => $data['home_visit_charge'] ?? null,
            'video_consult_charge'=> $data['video_consult_charge'] ?? null,
            'updated_at'          => now(),
        ], fn($v) => ! is_null($v));

        if ($profile) {
            DB::table('physiotherapist_profiles')->where('id', $profile->id)->update($payload);
        } else {
            DB::table('physiotherapist_profiles')->insert([
                'user_id'    => $user->id,
                'created_at' => now(),
                ...$payload,
            ]);
        }

        if (isset($data['name'])) {
            $user->update(['name' => $data['name']]);
        }

        $this->auditLogger->log($user, 'update_physio_profile', 'physiotherapist_profiles');

        return $this->getProfile($user);
    }

    public function getAvailability(User $user): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        return DB::table('physiotherapist_availability')
            ->where('physio_id', $profile->id)
            ->get()
            ->toArray();
    }

    public function updateAvailability(User $user, array $slots): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        // Replace all availability slots
        DB::table('physiotherapist_availability')->where('physio_id', $profile->id)->delete();

        $rows = array_map(fn($slot) => [
            'physio_id'   => $profile->id,
            'day_of_week' => $slot['day_of_week'],
            'start_time'  => $slot['start_time'],
            'end_time'    => $slot['end_time'],
            'is_active'   => $slot['is_active'] ?? true,
        ], $slots);

        DB::table('physiotherapist_availability')->insert($rows);

        return $this->getAvailability($user);
    }

    public function getDashboard(User $user): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        $todayBookings = DB::table('bookings')
            ->join('patient_profiles', 'bookings.patient_id', '=', 'patient_profiles.id')
            ->join('users', 'patient_profiles.user_id', '=', 'users.id')
            ->where('bookings.physio_id', $profile->id)
            ->where('bookings.scheduled_date', today())
            ->whereNotIn('bookings.status', ['cancelled', 'no_show'])
            ->select('bookings.*', 'users.name as patient_name', 'users.phone as patient_phone')
            ->orderBy('bookings.scheduled_time')
            ->get();

        $pendingBookings = DB::table('bookings')
            ->where('physio_id', $profile->id)
            ->where('status', 'pending')
            ->count();

        $monthEarnings = DB::table('bookings')
            ->where('physio_id', $profile->id)
            ->where('status', 'completed')
            ->whereMonth('completed_at', now()->month)
            ->whereYear('completed_at', now()->year)
            ->sum('session_fee');

        return [
            'is_verified'         => (bool) $profile->is_verified,
            'is_available'        => (bool) $profile->is_available,
            'today_bookings'      => $todayBookings,
            'pending_bookings'    => $pendingBookings,
            'month_earnings'      => $monthEarnings,
            'rating'              => $profile->rating,
            'total_sessions'      => $profile->total_sessions,
        ];
    }

    public function getPatients(User $user): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        return DB::table('bookings')
            ->join('patient_profiles', 'bookings.patient_id', '=', 'patient_profiles.id')
            ->join('users', 'patient_profiles.user_id', '=', 'users.id')
            ->where('bookings.physio_id', $profile->id)
            ->whereIn('bookings.status', ['confirmed', 'completed', 'in_session'])
            ->select(
                'patient_profiles.id',
                'users.name',
                'users.phone',
                'patient_profiles.gender',
                'patient_profiles.date_of_birth',
                DB::raw('MAX(bookings.scheduled_date) as last_session'),
                DB::raw('COUNT(bookings.id) as session_count')
            )
            ->groupBy('patient_profiles.id', 'users.name', 'users.phone', 'patient_profiles.gender', 'patient_profiles.date_of_birth')
            ->orderByDesc('last_session')
            ->get()
            ->toArray();
    }

    public function getPatientDetail(User $user, int $patientId): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        // Verify this physio has treated this patient
        $hasRelation = DB::table('bookings')
            ->where('physio_id', $profile->id)
            ->where('patient_id', $patientId)
            ->exists();

        abort_unless($hasRelation, 403, 'You do not have access to this patient.');

        $patientUser = DB::table('patient_profiles')
            ->join('users', 'patient_profiles.user_id', '=', 'users.id')
            ->where('patient_profiles.id', $patientId)
            ->select('patient_profiles.*', 'users.name', 'users.phone', 'users.email')
            ->first();

        $rehabPlan = DB::table('rehab_plans')
            ->where('patient_id', $patientId)
            ->where('physio_id', $profile->id)
            ->where('status', 'active')
            ->first();

        $scores = DB::table('patient_outcome_scores')
            ->where('patient_id', $patientId)
            ->orderByDesc('session_date')
            ->limit(20)
            ->get();

        return [
            'patient'    => $patientUser,
            'rehab_plan' => $rehabPlan,
            'scores'     => $scores,
        ];
    }

    public function getEarnings(User $user, string $period = 'month'): array
    {
        $profile = DB::table('physiotherapist_profiles')->where('user_id', $user->id)->firstOrFail();

        $query = DB::table('bookings')
            ->where('physio_id', $profile->id)
            ->where('status', 'completed')
            ->where('payment_status', 'captured');

        if ($period === 'month') {
            $query->whereMonth('completed_at', now()->month)->whereYear('completed_at', now()->year);
        } elseif ($period === 'week') {
            $query->whereBetween('completed_at', [now()->startOfWeek(), now()->endOfWeek()]);
        }

        $completedBookings = $query->get();

        $gross     = $completedBookings->sum('session_fee');
        $commission = $completedBookings->sum('platform_fee');

        $pendingPayout = DB::table('physio_payouts')
            ->where('physio_id', $profile->id)
            ->where('status', 'pending')
            ->sum('net_amount');

        return [
            'period'          => $period,
            'gross_earned'    => $gross,
            'commission_paid' => $commission,
            'net_earned'      => $gross - $commission,
            'sessions_count'  => $completedBookings->count(),
            'pending_payout'  => $pendingPayout,
            'recent_payouts'  => DB::table('physio_payouts')
                ->where('physio_id', $profile->id)
                ->orderByDesc('created_at')
                ->limit(5)
                ->get(),
        ];
    }

    public function updateLocation(User $user, float $lat, float $lng): void
    {
        DB::table('physiotherapist_profiles')
            ->where('user_id', $user->id)
            ->update([
                'current_latitude'    => $lat,
                'current_longitude'   => $lng,
                'location_updated_at' => now(),
            ]);
    }
}
