<?php

namespace App\Modules\Patient\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;

class PatientService
{
    public function __construct(private AuditLogger $auditLogger) {}

    public function getProfile(User $user): array
    {
        $profile = DB::table('patient_profiles')
            ->where('user_id', $user->id)
            ->first();

        $this->auditLogger->log($user, 'view_patient_profile', 'patient_profiles', $profile?->id);

        if (! $profile) return [];

        return $this->formatProfile($user, $profile);
    }

    public function upsertProfile(User $user, array $data): array
    {
        $profile = DB::table('patient_profiles')->where('user_id', $user->id)->first();

        $payload = [
            'date_of_birth'            => $data['date_of_birth'] ?? null,
            'gender'                   => $data['gender'] ?? null,
            'blood_group'              => $data['blood_group'] ?? null,
            'height_cm'                => $data['height_cm'] ?? null,
            'weight_kg'                => $data['weight_kg'] ?? null,
            'occupation'               => $data['occupation'] ?? null,
            'medical_history'          => isset($data['medical_history']) ? Crypt::encryptString($data['medical_history']) : null,
            'current_medications'      => isset($data['current_medications']) ? Crypt::encryptString($data['current_medications']) : null,
            'allergies'                => isset($data['allergies']) ? Crypt::encryptString($data['allergies']) : null,
            'emergency_contact_name'   => $data['emergency_contact_name'] ?? null,
            'emergency_contact_phone'  => $data['emergency_contact_phone'] ?? null,
            'preferred_language'       => $data['preferred_language'] ?? 'en',
            'updated_at'               => now(),
        ];

        if ($profile) {
            DB::table('patient_profiles')->where('user_id', $user->id)->update($payload);
        } else {
            DB::table('patient_profiles')->insert([
                'user_id'    => $user->id,
                'created_at' => now(),
                ...$payload,
            ]);
        }

        if (isset($data['name'])) {
            $user->update(['name' => $data['name']]);
        }

        $this->auditLogger->log($user, 'update_patient_profile', 'patient_profiles');

        return $this->getProfile($user);
    }

    public function getDashboard(User $user): array
    {
        $patientId = $this->getPatientId($user);

        $upcomingBookings = DB::table('bookings')
            ->where('patient_id', $patientId)
            ->whereIn('status', ['pending', 'confirmed'])
            ->where('scheduled_date', '>=', today())
            ->orderBy('scheduled_date')
            ->orderBy('scheduled_time')
            ->limit(3)
            ->get();

        $activeRehabPlan = DB::table('rehab_plans')
            ->where('patient_id', $patientId)
            ->where('status', 'active')
            ->first();

        $todayCheckin = DB::table('daily_checkins')
            ->where('patient_id', $patientId)
            ->where('checkin_date', today())
            ->first();

        $exercisesToday = $activeRehabPlan
            ? DB::table('phase_exercises')
                ->join('rehab_phases', 'phase_exercises.phase_id', '=', 'rehab_phases.id')
                ->join('exercises', 'phase_exercises.exercise_id', '=', 'exercises.id')
                ->where('rehab_phases.plan_id', $activeRehabPlan->id)
                ->where('rehab_phases.status', 'active')
                ->where('phase_exercises.is_active', true)
                ->select('phase_exercises.*', 'exercises.name', 'exercises.thumbnail_url', 'exercises.category')
                ->get()
            : collect();

        $xp = DB::table('patient_xp')->where('patient_id', $patientId)->first();

        return [
            'upcoming_bookings'  => $upcomingBookings,
            'active_rehab_plan'  => $activeRehabPlan,
            'checkin_done_today' => (bool) $todayCheckin,
            'exercises_today'    => $exercisesToday,
            'streak_days'        => $xp?->streak_days ?? 0,
            'level'              => $xp?->level ?? 1,
            'total_xp'           => $xp?->total_xp ?? 0,
        ];
    }

    public function getCheckins(User $user, int $days = 30): array
    {
        $patientId = $this->getPatientId($user);

        return DB::table('daily_checkins')
            ->where('patient_id', $patientId)
            ->where('checkin_date', '>=', today()->subDays($days))
            ->orderByDesc('checkin_date')
            ->get()
            ->toArray();
    }

    public function createCheckin(User $user, array $data): array
    {
        $patientId = $this->getPatientId($user);

        $existing = DB::table('daily_checkins')
            ->where('patient_id', $patientId)
            ->where('checkin_date', $data['checkin_date'] ?? today())
            ->first();

        if ($existing) {
            DB::table('daily_checkins')
                ->where('id', $existing->id)
                ->update([
                    'pain_score'   => $data['pain_score'] ?? $existing->pain_score,
                    'mood_score'   => $data['mood_score'] ?? $existing->mood_score,
                    'sleep_hours'  => $data['sleep_hours'] ?? $existing->sleep_hours,
                    'energy_level' => $data['energy_level'] ?? $existing->energy_level,
                    'patient_notes'=> $data['patient_notes'] ?? $existing->patient_notes,
                ]);
            return (array) DB::table('daily_checkins')->find($existing->id);
        }

        $id = DB::table('daily_checkins')->insertGetId([
            'patient_id'    => $patientId,
            'checkin_date'  => $data['checkin_date'] ?? today()->toDateString(),
            'pain_score'    => $data['pain_score'] ?? null,
            'mood_score'    => $data['mood_score'] ?? null,
            'sleep_hours'   => $data['sleep_hours'] ?? null,
            'energy_level'  => $data['energy_level'] ?? null,
            'patient_notes' => $data['patient_notes'] ?? null,
            'created_at'    => now(),
        ]);

        $this->updateStreak($patientId);

        return (array) DB::table('daily_checkins')->find($id);
    }

    public function getOutcomeScores(User $user, ?string $scoreCode = null): array
    {
        $patientId = $this->getPatientId($user);

        $query = DB::table('patient_outcome_scores')
            ->where('patient_id', $patientId)
            ->orderByDesc('session_date');

        if ($scoreCode) $query->where('score_code', $scoreCode);

        return $query->get()->toArray();
    }

    public function recordOutcomeScore(User $user, array $data): array
    {
        $patientId = $this->getPatientId($user);

        $definition = DB::table('outcome_score_definitions')
            ->where('code', $data['score_code'])
            ->first();

        $bandLabel = $this->interpretBand($definition, $data['raw_score']);

        $id = DB::table('patient_outcome_scores')->insertGetId([
            'patient_id'     => $patientId,
            'intake_id'      => $data['intake_id'] ?? null,
            'score_code'     => $data['score_code'],
            'raw_score'      => $data['raw_score'],
            'normalised_pct' => $this->normalise($definition, $data['raw_score']),
            'band_label'     => $bandLabel,
            'recorded_by'    => $user->id,
            'session_date'   => $data['session_date'] ?? today()->toDateString(),
            'week_number'    => $data['week_number'] ?? null,
            'notes'          => $data['notes'] ?? null,
            'created_at'     => now(),
        ]);

        $this->auditLogger->log($user, 'record_outcome_score', 'patient_outcome_scores', $id);

        return (array) DB::table('patient_outcome_scores')->find($id);
    }

    private function normalise($definition, float $rawScore): ?float
    {
        if (! $definition) return null;
        $range = $definition->score_max - $definition->score_min;
        if ($range <= 0) return null;
        $pct = (($rawScore - $definition->score_min) / $range) * 100;
        return $definition->lower_better ? round(100 - $pct, 2) : round($pct, 2);
    }

    private function interpretBand($definition, float $rawScore): ?string
    {
        if (! $definition || ! $definition->bands) return null;

        $bands = json_decode($definition->bands, true) ?? [];
        foreach ($bands as $band) {
            if ($rawScore >= $band['min'] && $rawScore <= $band['max']) {
                return $band['label'];
            }
        }

        return null;
    }

    private function updateStreak(int $patientId): void
    {
        $xp = DB::table('patient_xp')->where('patient_id', $patientId)->first();
        $today = today()->toDateString();

        if ($xp) {
            $last      = $xp->last_activity_date;
            $newStreak = ($last === today()->subDay()->toDateString())
                ? $xp->streak_days + 1
                : 1;

            DB::table('patient_xp')->where('patient_id', $patientId)->update([
                'streak_days'       => $newStreak,
                'longest_streak'    => max($xp->longest_streak, $newStreak),
                'last_activity_date'=> $today,
                'total_xp'          => $xp->total_xp + 10, // 10 XP per check-in
            ]);
        } else {
            DB::table('patient_xp')->insert([
                'patient_id'        => $patientId,
                'total_xp'          => 10,
                'level'             => 1,
                'streak_days'       => 1,
                'longest_streak'    => 1,
                'last_activity_date'=> $today,
            ]);
        }
    }

    private function getPatientId(User $user): int
    {
        $profile = DB::table('patient_profiles')->where('user_id', $user->id)->first();

        if (! $profile) {
            throw new \RuntimeException('Patient profile not found. Please complete your profile first.');
        }

        return $profile->id;
    }

    private function formatProfile(User $user, object $profile): array
    {
        $data = (array) $profile;

        // Decrypt sensitive fields
        foreach (['medical_history', 'current_medications', 'allergies'] as $field) {
            if (! empty($data[$field])) {
                try {
                    $data[$field] = Crypt::decryptString($data[$field]);
                } catch (\Throwable) {
                    $data[$field] = null;
                }
            }
        }

        $data['user'] = [
            'name'   => $user->name,
            'email'  => $user->email,
            'phone'  => $user->phone,
            'avatar' => $user->avatar_url,
        ];

        return $data;
    }
}
