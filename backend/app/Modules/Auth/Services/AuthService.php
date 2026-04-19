<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Models\User;
use App\Shared\Services\AuditLogger;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AuthService
{
    public function __construct(private AuditLogger $auditLogger) {}

    public function findOrCreateUser(string $phone, string $role = 'patient'): User
    {
        return DB::transaction(function () use ($phone, $role) {
            $user = User::where('phone', $phone)->first();

            if (! $user) {
                $user = User::create([
                    'uuid'              => (string) Str::uuid(),
                    'phone'             => $phone,
                    'name'              => 'User ' . substr($phone, -4),
                    'role'              => $role,
                    'status'            => 'pending',
                    'phone_verified_at' => now(),
                ]);
            } else {
                $user->update([
                    'phone_verified_at' => $user->phone_verified_at ?? now(),
                    'status'            => $user->status === 'deleted' ? 'pending' : $user->status,
                ]);
            }

            return $user;
        });
    }

    public function issueToken(User $user): array
    {
        // Expire old tokens beyond 30 days of inactivity
        $user->tokens()
            ->where('last_used_at', '<', now()->subDays(30))
            ->orWhereNull('last_used_at')
            ->where('created_at', '<', now()->subDays(30))
            ->delete();

        $token = $user->createToken('mobile', ['*'], now()->addDays(
            config('physioconnect.token.expiry_days', 30)
        ));

        $user->update(['last_login_at' => now()]);

        $this->auditLogger->log($user, 'login', 'users', $user->id);

        return [
            'token'      => $token->plainTextToken,
            'expires_at' => $token->accessToken->expires_at,
            'user'       => $this->userResource($user),
        ];
    }

    public function logout(User $user): void
    {
        $user->currentAccessToken()->delete();
        $this->auditLogger->log($user, 'logout', 'users', $user->id);
    }

    public function userResource(User $user): array
    {
        return [
            'id'                 => $user->id,
            'uuid'               => $user->uuid,
            'phone'              => $user->phone,
            'email'              => $user->email,
            'name'               => $user->name,
            'role'               => $user->role,
            'status'             => $user->status,
            'lang_preference'    => $user->lang_preference,
            'avatar_url'         => $user->avatar_url,
            'phone_verified_at'  => $user->phone_verified_at,
            'last_login_at'      => $user->last_login_at,
        ];
    }
}
