<?php

namespace App\Modules\Auth\Policies;

use App\Modules\Auth\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Auth\Access\HandlesAuthorization;

class PatientRecordPolicy
{
    use HandlesAuthorization;

    public function view(User $user, Model $patient): bool
    {
        $patientUserId = $patient->user_id ?? $patient->id;

        return match ($user->role) {
            'patient'         => $user->id === $patientUserId,
            'physiotherapist' => $this->physioHasActiveRelation($user->id, $patient),
            'surgeon'         => $this->surgeonHasSurgicalRecord($user->id, $patient),
            'psychologist'    => $this->psychologistInCareTeam($user->id, $patient),
            'admin', 'super_admin' => true,
            default           => false,
        };
    }

    public function update(User $user, Model $patient): bool
    {
        return match ($user->role) {
            'patient'         => $user->id === ($patient->user_id ?? $patient->id),
            'physiotherapist' => $this->physioHasActiveRelation($user->id, $patient),
            'admin', 'super_admin' => true,
            default           => false,
        };
    }

    private function physioHasActiveRelation(int $physioUserId, Model $patient): bool
    {
        $patientId = $patient->id ?? null;
        if (! $patientId) return false;

        return \DB::table('bookings')
            ->join('physiotherapist_profiles', 'bookings.physio_id', '=', 'physiotherapist_profiles.id')
            ->where('physiotherapist_profiles.user_id', $physioUserId)
            ->where('bookings.patient_id', $patientId)
            ->whereIn('bookings.status', ['confirmed', 'physio_en_route', 'arrived', 'in_session', 'completed'])
            ->exists();
    }

    private function surgeonHasSurgicalRecord(int $surgeonUserId, Model $patient): bool
    {
        $patientId = $patient->id ?? null;
        if (! $patientId) return false;

        return \DB::table('surgical_records')
            ->join('surgeon_profiles', 'surgical_records.surgeon_id', '=', 'surgeon_profiles.id')
            ->where('surgeon_profiles.user_id', $surgeonUserId)
            ->where('surgical_records.patient_id', $patientId)
            ->exists();
    }

    private function psychologistInCareTeam(int $psychUserId, Model $patient): bool
    {
        $patientId = $patient->id ?? null;
        if (! $patientId) return false;

        return \DB::table('care_teams')
            ->join('psychologist_profiles', 'care_teams.psychologist_id', '=', 'psychologist_profiles.id')
            ->where('psychologist_profiles.user_id', $psychUserId)
            ->where('care_teams.patient_id', $patientId)
            ->where('care_teams.is_active', true)
            ->exists();
    }
}
