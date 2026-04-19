<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;

    protected function createUser(string $role = 'patient', string $status = 'active'): object
    {
        $userId = DB::table('users')->insertGetId([
            'uuid'              => (string) Str::uuid(),
            'phone'             => '9' . str_pad((string) rand(0, 999999999), 9, '0', STR_PAD_LEFT),
            'name'              => ucfirst($role) . ' User',
            'role'              => $role,
            'status'            => $status,
            'phone_verified_at' => now(),
            'created_at'        => now(),
            'updated_at'        => now(),
        ]);

        return DB::table('users')->find($userId);
    }

    protected function createPatientProfile(int $userId): object
    {
        $id = DB::table('patient_profiles')->insertGetId([
            'user_id'    => $userId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return DB::table('patient_profiles')->find($id);
    }

    protected function createPhysioProfile(int $userId, bool $verified = true): object
    {
        $id = DB::table('physiotherapist_profiles')->insertGetId([
            'user_id'             => $userId,
            'registration_number' => 'IPA-TEST-' . rand(1000, 9999),
            'qualification'       => 'BPT',
            'is_verified'         => $verified,
            'is_available'        => true,
            'home_visit_charge'   => 800.00,
            'rating'              => 4.50,
            'current_latitude'    => 23.0225,
            'current_longitude'   => 72.5714,
            'location_updated_at' => now(),
            'created_at'          => now(),
            'updated_at'          => now(),
        ]);

        return DB::table('physiotherapist_profiles')->find($id);
    }

    protected function actingAsUser(object $user): static
    {
        $userModel = \App\Modules\Auth\Models\User::find($user->id);
        return $this->actingAs($userModel, 'sanctum');
    }

    protected function assertApiSuccess(\Illuminate\Testing\TestResponse $response, int $expectedStatus = 200): void
    {
        $response->assertStatus($expectedStatus);
        $response->assertJsonPath('success', true);
    }

    protected function assertApiError(\Illuminate\Testing\TestResponse $response, int $expectedStatus): void
    {
        $response->assertStatus($expectedStatus);
        $response->assertJsonPath('success', false);
    }
}
