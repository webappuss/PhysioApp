<?php

namespace Tests\Feature\Auth;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_send_otp_requires_valid_phone(): void
    {
        $response = $this->postJson('/api/v1/auth/send-otp', ['phone' => '123']);

        $this->assertApiError($response, 422);
        $response->assertJsonPath('code', 'VALIDATION_ERROR');
    }

    public function test_send_otp_rejects_non_indian_number(): void
    {
        $response = $this->postJson('/api/v1/auth/send-otp', ['phone' => '1234567890']);

        $this->assertApiError($response, 422);
    }

    public function test_send_otp_accepts_valid_indian_number(): void
    {
        $response = $this->postJson('/api/v1/auth/send-otp', ['phone' => '9876543210']);

        $this->assertApiSuccess($response);
    }

    public function test_verify_otp_with_invalid_otp_returns_error(): void
    {
        // Create an OTP record
        \DB::table('otp_verifications')->insert([
            'phone'      => '9876543210',
            'otp_hash'   => Hash::make('123456'),
            'purpose'    => 'login',
            'expires_at' => now()->addMinutes(10),
            'verified'   => false,
            'attempts'   => 0,
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '9876543210',
            'otp'   => '999999',
        ]);

        $this->assertApiError($response, 422);
    }

    public function test_verify_otp_with_valid_otp_issues_token(): void
    {
        \DB::table('otp_verifications')->insert([
            'phone'      => '9876543210',
            'otp_hash'   => Hash::make('123456'),
            'purpose'    => 'login',
            'expires_at' => now()->addMinutes(10),
            'verified'   => false,
            'attempts'   => 0,
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '9876543210',
            'otp'   => '123456',
        ]);

        $this->assertApiSuccess($response);
        $response->assertJsonStructure([
            'data' => ['token', 'expires_at', 'user' => ['id', 'phone', 'role']],
        ]);
    }

    public function test_expired_otp_returns_error(): void
    {
        \DB::table('otp_verifications')->insert([
            'phone'      => '9876543210',
            'otp_hash'   => Hash::make('123456'),
            'purpose'    => 'login',
            'expires_at' => now()->subMinutes(5), // already expired
            'verified'   => false,
            'attempts'   => 0,
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '9876543210',
            'otp'   => '123456',
        ]);

        $this->assertApiError($response, 422);
        $response->assertJsonPath('errors.otp.0', 'OTP has expired. Please request a new one.');
    }

    public function test_me_endpoint_returns_user_data(): void
    {
        $user = $this->createUser('patient');
        $this->createPatientProfile($user->id);

        $response = $this->actingAsUser($user)->getJson('/api/v1/auth/me');

        $this->assertApiSuccess($response);
        $response->assertJsonPath('data.phone', $user->phone);
        $response->assertJsonPath('data.role', 'patient');
    }

    public function test_me_endpoint_requires_authentication(): void
    {
        $response = $this->getJson('/api/v1/auth/me');

        $this->assertApiError($response, 401);
    }

    public function test_logout_invalidates_token(): void
    {
        $user = $this->createUser('patient');

        $response = $this->actingAsUser($user)->postJson('/api/v1/auth/logout');

        $this->assertApiSuccess($response);
    }

    public function test_otp_rate_limit_prevents_spam(): void
    {
        // Pre-fill rate limit cache
        Cache::put('otp_send:9876543210', 5, now()->addHour());

        $response = $this->postJson('/api/v1/auth/send-otp', ['phone' => '9876543210']);

        $this->assertApiError($response, 422);
    }
}
