<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('users')->insertOrIgnore([
            'uuid'               => Str::uuid(),
            'phone'              => '9000000000',
            'email'              => 'admin@physioconnect.in',
            'password'           => Hash::make(env('ADMIN_DEFAULT_PASSWORD', 'PhysioAdmin@2026!')),
            'name'               => 'Super Admin',
            'role'               => 'super_admin',
            'status'             => 'active',
            'phone_verified_at'  => now(),
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);
    }
}
