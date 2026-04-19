<?php

namespace App\Modules\Booking\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use App\Shared\Services\NotificationService;
use App\Shared\Services\RazorpayService;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class BookingService
{
    public function __construct(
        private AuditLogger         $auditLogger,
        private NotificationService $notificationService,
        private RazorpayService     $razorpayService,
    ) {}

    public function create(User $user, array $data): array
    {
        $patientProfile = DB::table('patient_profiles')->where('user_id', $user->id)->firstOrFail();
        $physioProfile  = DB::table('physiotherapist_profiles')
            ->where('id', $data['physio_id'])
            ->where('is_verified', true)
            ->where('is_available', true)
            ->firstOrFail();

        // Prevent double-booking same slot
        $conflict = DB::table('bookings')
            ->where('physio_id', $physioProfile->id)
            ->where('scheduled_date', $data['scheduled_date'])
            ->where('scheduled_time', $data['scheduled_time'])
            ->whereNotIn('status', ['cancelled', 'no_show'])
            ->exists();

        if ($conflict) {
            throw ValidationException::withMessages([
                'scheduled_time' => ['This time slot is no longer available. Please choose another.'],
            ]);
        }

        $fees = $this->razorpayService->calculateFees(
            $physioProfile->home_visit_charge,
            $data['booking_type']
        );

        $bookingId = DB::table('bookings')->insertGetId([
            'uuid'           => (string) Str::uuid(),
            'patient_id'     => $patientProfile->id,
            'physio_id'      => $physioProfile->id,
            'booking_type'   => $data['booking_type'],
            'status'         => 'pending',
            'scheduled_date' => $data['scheduled_date'],
            'scheduled_time' => $data['scheduled_time'],
            'address_id'     => $data['address_id'] ?? null,
            'session_fee'    => $fees['session_fee'],
            'platform_fee'   => $fees['platform_fee'],
            'total_amount'   => $fees['total_amount'],
            'payment_status' => 'pending',
            'package_id'     => $data['package_id'] ?? null,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        $booking = DB::table('bookings')->find($bookingId);

        $this->auditLogger->log($user, 'create_booking', 'bookings', $bookingId);

        // Notify physio
        $physioUser = DB::table('users')
            ->join('physiotherapist_profiles', 'users.id', '=', 'physiotherapist_profiles.user_id')
            ->where('physiotherapist_profiles.id', $physioProfile->id)
            ->value('users.id');

        if ($physioUser) {
            $this->notificationService->notifyBookingConfirmed(
                $user->id,
                $physioUser,
                ['date' => $data['scheduled_date'], 'time' => $data['scheduled_time'], 'uuid' => $booking->uuid]
            );
        }

        return (array) $booking;
    }

    public function get(int $bookingId, User $user): array
    {
        $booking = DB::table('bookings')
            ->join('patient_profiles', 'bookings.patient_id', '=', 'patient_profiles.id')
            ->join('users as pu', 'patient_profiles.user_id', '=', 'pu.id')
            ->join('physiotherapist_profiles', 'bookings.physio_id', '=', 'physiotherapist_profiles.id')
            ->join('users as phu', 'physiotherapist_profiles.user_id', '=', 'phu.id')
            ->where('bookings.id', $bookingId)
            ->select(
                'bookings.*',
                'pu.name as patient_name',
                'pu.phone as patient_phone',
                'phu.name as physio_name',
                'phu.phone as physio_phone',
                'phu.avatar_url as physio_avatar',
                'physiotherapist_profiles.qualification as physio_qualification',
                'physiotherapist_profiles.rating as physio_rating',
            )
            ->firstOrFail();

        $this->auditLogger->log($user, 'view_booking', 'bookings', $bookingId);

        return (array) $booking;
    }

    public function transition(int $bookingId, User $user, string $action, array $data = []): array
    {
        $booking = DB::table('bookings')->find($bookingId);
        abort_if(! $booking, 404, 'Booking not found.');

        $updates = match ($action) {
            'confirm'  => $this->confirmBooking($booking, $user),
            'start'    => $this->startBooking($booking, $user),
            'complete' => $this->completeBooking($booking, $user),
            'cancel'   => $this->cancelBooking($booking, $user, $data),
            default    => throw new \InvalidArgumentException("Unknown action: {$action}"),
        };

        DB::table('bookings')->where('id', $bookingId)->update($updates + ['updated_at' => now()]);

        $this->auditLogger->log($user, "booking_{$action}", 'bookings', $bookingId);

        return (array) DB::table('bookings')->find($bookingId);
    }

    public function getTracking(int $bookingId): array
    {
        $latest = DB::table('booking_tracking')
            ->where('booking_id', $bookingId)
            ->latest('recorded_at')
            ->first();

        return $latest ? (array) $latest : [];
    }

    public function recordTracking(int $bookingId, float $lat, float $lng): void
    {
        DB::table('booking_tracking')->insert([
            'booking_id'  => $bookingId,
            'latitude'    => $lat,
            'longitude'   => $lng,
            'recorded_at' => now(),
        ]);
    }

    public function createSession(User $user, array $data): array
    {
        $booking = DB::table('bookings')->find($data['booking_id']);
        abort_if(! $booking, 404, 'Booking not found.');

        $sessionId = DB::table('sessions')->insertGetId([
            'uuid'           => (string) Str::uuid(),
            'booking_id'     => $booking->id,
            'patient_id'     => $booking->patient_id,
            'physio_id'      => $booking->physio_id,
            'session_number' => $data['session_number'] ?? null,
            'pain_at_start'  => $data['pain_at_start'] ?? null,
            'pain_at_end'    => $data['pain_at_end'] ?? null,
            'techniques_used'=> isset($data['techniques_used']) ? json_encode($data['techniques_used']) : null,
            'duration_mins'  => $data['duration_mins'] ?? null,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        $this->auditLogger->log($user, 'create_session', 'sessions', $sessionId);

        return (array) DB::table('sessions')->find($sessionId);
    }

    public function updateSoap(User $user, int $sessionId, array $data): array
    {
        $session = DB::table('sessions')->find($sessionId);
        abort_if(! $session, 404, 'Session not found.');

        DB::table('sessions')->where('id', $sessionId)->update([
            'subjective' => isset($data['subjective']) ? Crypt::encryptString($data['subjective']) : $session->subjective,
            'objective'  => isset($data['objective'])  ? Crypt::encryptString($data['objective'])  : $session->objective,
            'assessment' => isset($data['assessment']) ? Crypt::encryptString($data['assessment']) : $session->assessment,
            'plan'       => isset($data['plan'])       ? Crypt::encryptString($data['plan'])       : $session->plan,
            'pain_at_start' => $data['pain_at_start'] ?? $session->pain_at_start,
            'pain_at_end'   => $data['pain_at_end']   ?? $session->pain_at_end,
            'techniques_used' => isset($data['techniques_used']) ? json_encode($data['techniques_used']) : $session->techniques_used,
            'duration_mins'   => $data['duration_mins'] ?? $session->duration_mins,
            'updated_at'      => now(),
        ]);

        $this->auditLogger->log($user, 'update_soap', 'sessions', $sessionId);

        return $this->getSessionWithDecryptedSoap($sessionId, $user);
    }

    public function getSession(int $sessionId, User $user): array
    {
        return $this->getSessionWithDecryptedSoap($sessionId, $user);
    }

    private function getSessionWithDecryptedSoap(int $sessionId, User $user): array
    {
        $session = DB::table('sessions')->find($sessionId);
        abort_if(! $session, 404, 'Session not found.');

        $data = (array) $session;
        foreach (['subjective', 'objective', 'assessment', 'plan'] as $field) {
            if (! empty($data[$field])) {
                try {
                    $data[$field] = Crypt::decryptString($data[$field]);
                } catch (\Throwable) {
                    $data[$field] = null;
                }
            }
        }

        $this->auditLogger->log($user, 'view_soap', 'sessions', $sessionId);

        return $data;
    }

    private function confirmBooking(object $booking, User $user): array
    {
        abort_unless($booking->status === 'pending', 422, 'Only pending bookings can be confirmed.');
        return ['status' => 'confirmed', 'confirmed_at' => now()];
    }

    private function startBooking(object $booking, User $user): array
    {
        abort_unless(in_array($booking->status, ['confirmed', 'physio_en_route']), 422, 'Cannot start this booking.');

        $patientUserId = DB::table('patient_profiles')->where('id', $booking->patient_id)->value('user_id');
        $this->notificationService->notifyPhysioEnRoute($patientUserId, ['uuid' => $booking->uuid]);

        return ['status' => 'physio_en_route', 'started_at' => now()];
    }

    private function completeBooking(object $booking, User $user): array
    {
        abort_unless(in_array($booking->status, ['arrived', 'in_session']), 422, 'Cannot complete this booking.');

        // Increment physio total_sessions
        DB::table('physiotherapist_profiles')
            ->where('id', $booking->physio_id)
            ->increment('total_sessions');

        return ['status' => 'completed', 'completed_at' => now()];
    }

    private function cancelBooking(object $booking, User $user, array $data): array
    {
        abort_unless(in_array($booking->status, ['pending', 'confirmed']), 422, 'This booking cannot be cancelled.');

        return [
            'status'              => 'cancelled',
            'cancellation_reason' => $data['reason'] ?? null,
            'cancelled_by'        => $user->id,
            'cancelled_at'        => now(),
        ];
    }
}
