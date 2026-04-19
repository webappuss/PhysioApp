<?php

namespace Tests\Feature\Booking;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class BookingTest extends TestCase
{
    use RefreshDatabase;

    public function test_patient_can_create_booking(): void
    {
        $patientUser = $this->createUser('patient');
        $this->createPatientProfile($patientUser->id);

        $physioUser = $this->createUser('physiotherapist');
        $physio     = $this->createPhysioProfile($physioUser->id);

        $response = $this->actingAsUser($patientUser)->postJson('/api/v1/bookings', [
            'physio_id'      => $physio->id,
            'booking_type'   => 'home_visit',
            'scheduled_date' => now()->addDay()->toDateString(),
            'scheduled_time' => '10:00',
        ]);

        $this->assertApiSuccess($response, 201);
        $response->assertJsonStructure(['data' => ['id', 'uuid', 'status', 'total_amount']]);
        $response->assertJsonPath('data.status', 'pending');
    }

    public function test_physio_cannot_create_booking(): void
    {
        $physioUser = $this->createUser('physiotherapist');
        $this->createPhysioProfile($physioUser->id);

        $physio2 = $this->createUser('physiotherapist');
        $p2      = $this->createPhysioProfile($physio2->id);

        $response = $this->actingAsUser($physioUser)->postJson('/api/v1/bookings', [
            'physio_id'      => $p2->id,
            'booking_type'   => 'home_visit',
            'scheduled_date' => now()->addDay()->toDateString(),
            'scheduled_time' => '10:00',
        ]);

        $this->assertApiError($response, 403);
    }

    public function test_physio_can_confirm_booking(): void
    {
        [$bookingId, $physioUser] = $this->createPendingBooking();

        $response = $this->actingAsUser($physioUser)->putJson("/api/v1/bookings/{$bookingId}/confirm");

        $this->assertApiSuccess($response);
        $response->assertJsonPath('data.status', 'confirmed');
    }

    public function test_booking_cannot_be_double_booked(): void
    {
        $patientUser = $this->createUser('patient');
        $this->createPatientProfile($patientUser->id);
        $physioUser  = $this->createUser('physiotherapist');
        $physio      = $this->createPhysioProfile($physioUser->id);

        $date = now()->addDay()->toDateString();

        // First booking
        \DB::table('bookings')->insert([
            'uuid'           => (string) Str::uuid(),
            'patient_id'     => \DB::table('patient_profiles')->where('user_id', $patientUser->id)->value('id'),
            'physio_id'      => $physio->id,
            'booking_type'   => 'home_visit',
            'status'         => 'confirmed',
            'scheduled_date' => $date,
            'scheduled_time' => '10:00:00',
            'session_fee'    => 800,
            'platform_fee'   => 170,
            'total_amount'   => 970,
            'payment_status' => 'pending',
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        // Attempt duplicate
        $response = $this->actingAsUser($patientUser)->postJson('/api/v1/bookings', [
            'physio_id'      => $physio->id,
            'booking_type'   => 'home_visit',
            'scheduled_date' => $date,
            'scheduled_time' => '10:00',
        ]);

        $this->assertApiError($response, 422);
        $response->assertJsonPath('errors.scheduled_time.0', 'This time slot is no longer available. Please choose another.');
    }

    public function test_patient_can_cancel_pending_booking(): void
    {
        [$bookingId, , $patientUser] = $this->createPendingBooking();

        $response = $this->actingAsUser($patientUser)->putJson("/api/v1/bookings/{$bookingId}/cancel", [
            'reason' => 'Change of plans',
        ]);

        $this->assertApiSuccess($response);
        $response->assertJsonPath('data.status', 'cancelled');
    }

    public function test_cannot_cancel_completed_booking(): void
    {
        [$bookingId, , $patientUser] = $this->createPendingBooking();

        // Force complete
        \DB::table('bookings')->where('id', $bookingId)
            ->update(['status' => 'completed', 'completed_at' => now()]);

        $response = $this->actingAsUser($patientUser)->putJson("/api/v1/bookings/{$bookingId}/cancel");

        $this->assertApiError($response, 422);
    }

    public function test_booking_tracking_returns_empty_when_no_location(): void
    {
        [$bookingId, , $patientUser] = $this->createPendingBooking();

        $response = $this->actingAsUser($patientUser)->getJson("/api/v1/bookings/{$bookingId}/tracking");

        $this->assertApiSuccess($response);
        $this->assertEmpty($response->json('data'));
    }

    public function test_unauthenticated_cannot_access_bookings(): void
    {
        $response = $this->postJson('/api/v1/bookings', []);

        $this->assertApiError($response, 401);
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private function createPendingBooking(): array
    {
        $patientUser = $this->createUser('patient');
        $patient     = $this->createPatientProfile($patientUser->id);
        $physioUser  = $this->createUser('physiotherapist');
        $physio      = $this->createPhysioProfile($physioUser->id);

        $bookingId = \DB::table('bookings')->insertGetId([
            'uuid'           => (string) Str::uuid(),
            'patient_id'     => $patient->id,
            'physio_id'      => $physio->id,
            'booking_type'   => 'home_visit',
            'status'         => 'pending',
            'scheduled_date' => now()->addDay()->toDateString(),
            'scheduled_time' => '11:00:00',
            'session_fee'    => 800,
            'platform_fee'   => 170,
            'total_amount'   => 970,
            'payment_status' => 'pending',
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        return [$bookingId, $physioUser, $patientUser];
    }
}
