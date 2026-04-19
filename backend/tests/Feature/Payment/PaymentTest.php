<?php

namespace Tests\Feature\Payment;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    public function test_patient_can_create_payment_order(): void
    {
        [$bookingId, $patientUser] = $this->createBookingWithPatient();

        // Mock Razorpay HTTP call
        \Illuminate\Support\Facades\Http::fake([
            'api.razorpay.com/*' => \Illuminate\Support\Facades\Http::response([
                'id'       => 'order_test_123',
                'amount'   => 97000,
                'currency' => 'INR',
                'status'   => 'created',
            ], 200),
        ]);

        $response = $this->actingAsUser($patientUser)->postJson('/api/v1/payments/create-order', [
            'booking_id' => $bookingId,
        ]);

        $this->assertApiSuccess($response, 201);
        $response->assertJsonStructure([
            'data' => ['razorpay_order_id', 'amount', 'amount_paise', 'key_id'],
        ]);
    }

    public function test_payment_verify_fails_on_invalid_signature(): void
    {
        [, $patientUser] = $this->createBookingWithPatient();

        // Insert a payment record
        \DB::table('payments')->insert([
            'uuid'              => (string) Str::uuid(),
            'patient_id'        => \DB::table('patient_profiles')->where('user_id', $patientUser->id)->value('id'),
            'amount'            => 970,
            'razorpay_order_id' => 'order_fake_123',
            'status'            => 'created',
            'created_at'        => now(),
            'updated_at'        => now(),
        ]);

        $response = $this->actingAsUser($patientUser)->postJson('/api/v1/payments/verify', [
            'razorpay_order_id'   => 'order_fake_123',
            'razorpay_payment_id' => 'pay_fake_456',
            'razorpay_signature'  => 'invalidsignature',
        ]);

        $this->assertApiError($response, 422);
        $response->assertJsonPath('errors.signature.0', 'Payment verification failed. Please contact support.');
    }

    public function test_payment_history_returns_patient_payments(): void
    {
        [, $patientUser] = $this->createBookingWithPatient();
        $patientId = \DB::table('patient_profiles')->where('user_id', $patientUser->id)->value('id');

        \DB::table('payments')->insert([
            'uuid'       => (string) Str::uuid(),
            'patient_id' => $patientId,
            'amount'     => 970,
            'status'     => 'captured',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->actingAsUser($patientUser)->getJson('/api/v1/payments/history');

        $this->assertApiSuccess($response);
        $this->assertCount(1, $response->json('data'));
    }

    public function test_physio_cannot_access_payment_history(): void
    {
        $physioUser = $this->createUser('physiotherapist');
        $this->createPhysioProfile($physioUser->id);

        $response = $this->actingAsUser($physioUser)->getJson('/api/v1/payments/history');

        $this->assertApiError($response, 403);
    }

    public function test_webhook_rejects_invalid_signature(): void
    {
        $response = $this->postJson('/api/v1/payments/webhook', [], [
            'X-Razorpay-Signature' => 'badsignature',
        ]);

        $response->assertStatus(400);
    }

    private function createBookingWithPatient(): array
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
            'status'         => 'confirmed',
            'scheduled_date' => now()->addDay()->toDateString(),
            'scheduled_time' => '10:00:00',
            'session_fee'    => 800,
            'platform_fee'   => 170,
            'total_amount'   => 970,
            'payment_status' => 'pending',
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        return [$bookingId, $patientUser];
    }
}
